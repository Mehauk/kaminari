import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/constants/prompt.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/data/services/network_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'background_webview_cubit.freezed.dart';

@freezed
abstract class DownloadTask with _$DownloadTask {
  const factory DownloadTask({
    required int bookId,
    required ChapterInfo chapter,
    @Default(false) bool isPriority,
    @Default(false) bool forceReloadSelectors,
  }) = _DownloadTask;
}

@freezed
abstract class BackgroundWebviewState with _$BackgroundWebviewState {
  const factory BackgroundWebviewState({
    @Default(false) bool isProcessing,
    int? activeChapterId,
    @Default([]) List<int> completedChapterIds,
    String? errorMessage,
  }) = _BackgroundWebviewState;
}

class BackgroundWebviewCubit extends Cubit<BackgroundWebviewState> {
  final DatabaseService dbService;
  final ExtractorBuilder extractorBuilder;
  final NetworkService networkService;
  final AppSettings appSettings;
  late final WebViewController _controller;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  // Queue Management
  final List<DownloadTask> _queue = [];
  final List<DateTime> _downloadTimestamps = [];
  bool _isLoopRunning = false;

  BackgroundWebviewCubit({
    required this.dbService,
    required this.extractorBuilder,
    required this.networkService,
    required this.appSettings,
  }) : super(const BackgroundWebviewState()) {
    _initController();
    _connectivitySubscription = networkService.onConnectivityChanged.listen((
      connectivityResult,
    ) {
      if (_queue.isNotEmpty &&
          !_isLoopRunning &&
          (networkService.isWifiOrEthernet(connectivityResult) ||
              appSettings.getDownloadOverMobile())) {
        _processQueue();
      }
    });
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageLoadCompleter?.complete();
          },
        ),
      )
      ..addJavaScriptChannel(
        'ExtractionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _extractionCompleter?.complete(message.message);
        },
      );
  }

  /// Adds chapters to the download queue.
  /// [isPriority] skips rate limiting and puts tasks at the top of the stack.
  Future<void> enqueueChapters({
    required int bookId,
    required List<ChapterInfo> chapters,
    bool isPriority = false,
    bool forceReloadSelectors = false,
  }) async {
    // Filter out local files or epub virtual links
    final webChapters = chapters
        .where(
          (c) => !c.url.startsWith('epub://') && !c.url.startsWith('file://'),
        )
        .toList();

    if (webChapters.isEmpty) {
      return;
    }

    for (var chapter in webChapters) {
      // Avoid duplicates in queue
      _queue.removeWhere((t) => t.chapter.id == chapter.id);

      final task = DownloadTask(
        bookId: bookId,
        chapter: chapter,
        isPriority: isPriority,
        forceReloadSelectors: forceReloadSelectors,
      );

      if (isPriority) {
        _queue.insert(0, task);
      } else {
        _queue.add(task);
        // Sort non-priority items: smallest chapter number first
        final priorityTasks = _queue.where((t) => t.isPriority).toList();
        final regularTasks = _queue.where((t) => !t.isPriority).toList();
        regularTasks.sort(
          (a, b) => a.chapter.number.compareTo(b.chapter.number),
        );

        _queue.clear();
        _queue.addAll(priorityTasks);
        _queue.addAll(regularTasks);
      }
    }

    if (!_isLoopRunning) {
      _isLoopRunning = true;
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || !await _isDownloadAllowed()) {
      _isLoopRunning = false;
      return;
    }

    while (true) {
      if (_queue.isEmpty) {
        break;
      }

      if (!await _isDownloadAllowed()) {
        break;
      }

      final task = _queue.removeAt(0);

      // Rate limit check: 5 per minute (ignore if priority)
      if (!task.isPriority) {
        await _enforceRateLimit();
      }

      emit(
        state.copyWith(isProcessing: true, activeChapterId: task.chapter.id),
      );

      try {
        await _extractChapterContent(task.chapter, task.forceReloadSelectors);
        _downloadTimestamps.add(DateTime.now());

        // Notify UI that a specific chapter is done
        emit(
          state.copyWith(
            completedChapterIds: [
              ...state.completedChapterIds,
              task.chapter.id!,
            ],
          ),
        );
      } catch (e) {
        print("Background download error: $e");
      } finally {
        emit(state.copyWith(activeChapterId: null));
      }
    }

    _isLoopRunning = false;
    emit(state.copyWith(isProcessing: false));
  }

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    // Keep only timestamps from the last minute
    _downloadTimestamps.removeWhere((t) => now.difference(t).inMinutes >= 1);

    if (_downloadTimestamps.length >= 5) {
      final oldest = _downloadTimestamps.first;
      final waitTime = const Duration(minutes: 1) - now.difference(oldest);
      if (waitTime > Duration.zero) {
        print("Rate limit reached. Waiting ${waitTime.inSeconds}s...");
        await Future.delayed(waitTime);
      }
    }
  }

  Future<void> _extractChapterContent(
    ChapterInfo chapter,
    bool forceReloadSelectors,
  ) async {
    final origin = Uri.parse(chapter.url).origin;
    await _loadUrl(chapter.url);

    final dynamic chapterTreeRaw = await _controller
        .runJavaScriptReturningResult(minTreeExtFn);
    final String chapterTree = chapterTreeRaw as String;
    final chapterPrompt = buildChapterExtractionAIPrompt(chapterTree);

    final chapterLlmResponse = await extractorBuilder
        .buildChapterExtractorSelectors(
          origin,
          chapterPrompt,
          forceReload: forceReloadSelectors,
        );
    final chapterExtractor = LlmService.extractJsonFromResponse(
      chapterLlmResponse,
      ChapterExtractor.fromJson,
    );

    final contentJs = generateContentExtractionJSPrompt(
      jsonEncode([chapter.url]),
      jsonEncode(chapterExtractor.contentSections),
    );

    _extractionCompleter = Completer<String>();
    await _controller.runJavaScript(contentJs);

    final result = await _extractionCompleter!.future.timeout(
      const Duration(minutes: 2),
    );
    final response = jsonDecode(result);

    // If JavaScript threw an error, catch and log it in Dart
    if (response.containsKey('error')) {
      throw Exception("JavaScript Extraction Failed: ${response['error']}");
    }

    if (response.containsKey('contents')) {
      final List contents = response['contents'][0];
      final List<String> stringContents = contents
          .map((e) => e.toString())
          .toList();
      if (stringContents.isNotEmpty) {
        print("chapter number: ${chapter.number}");
        await dbService.saveChapterContent(chapter.id!, stringContents);
      }
    }
  }

  Future<void> _loadUrl(String url) async {
    _pageLoadCompleter = Completer<void>();
    await _controller.loadRequest(Uri.parse(url));
    await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
    _pageLoadCompleter = null;
  }

  Future<bool> _isDownloadAllowed() async {
    final connectivityResult = await networkService.checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      print('Background downloads paused: offline mode.');
      return false;
    }

    if (networkService.isWifiOrEthernet(connectivityResult)) {
      return true;
    }

    if (appSettings.getDownloadOverMobile()) {
      return true;
    }

    print('Background downloads paused: mobile data connection.');
    return false;
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
