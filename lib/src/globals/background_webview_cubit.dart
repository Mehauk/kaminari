import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/constants/prompt.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'background_webview_cubit.freezed.dart';

@freezed
abstract class DownloadTask with _$DownloadTask {
  const factory DownloadTask({
    required int bookId,
    required ChapterInfo chapter,
    @Default(false) bool isPriority,
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
  late final WebViewController _controller;

  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  // Queue Management
  final List<DownloadTask> _queue = [];
  final List<DateTime> _downloadTimestamps = [];
  bool _isLoopRunning = false;

  BackgroundWebviewCubit({
    required this.dbService,
    required this.extractorBuilder,
  }) : super(const BackgroundWebviewState()) {
    _initController();
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
  }) async {
    for (var chapter in chapters) {
      // Avoid duplicates in queue
      _queue.removeWhere((t) => t.chapter.id == chapter.id);

      final task = DownloadTask(
        bookId: bookId,
        chapter: chapter,
        isPriority: isPriority,
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
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isLoopRunning = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);

      // Rate limit check: 5 per minute (ignore if priority)
      if (!task.isPriority) {
        await _enforceRateLimit();
      }

      emit(
        state.copyWith(isProcessing: true, activeChapterId: task.chapter.id),
      );

      try {
        await _extractChapterContent(task.chapter);
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

  Future<void> _extractChapterContent(ChapterInfo chapter) async {
    final origin = Uri.parse(chapter.url).origin;
    await _loadUrl(chapter.url);

    final dynamic chapterTreeRaw = await _controller
        .runJavaScriptReturningResult(minTreeExtFn);
    final String chapterTree = chapterTreeRaw as String;
    final chapterPrompt = buildChapterExtractionAIPrompt(chapterTree);

    final chapterLlmResponse = await extractorBuilder
        .buildChapterExtractorSelectors(origin, chapterPrompt);

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

    if (response.containsKey('contents')) {
      final List contents = response['contents'][0];
      final List<String> stringContents = contents
          .map((e) => e.toString())
          .toList();
      if (stringContents.isNotEmpty) {
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
}
