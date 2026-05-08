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
abstract class BackgroundWebviewState with _$BackgroundWebviewState {
  const factory BackgroundWebviewState({
    @Default(false) bool isPrefetching,
    int? activeBookId,
    String? errorMessage,
  }) = _BackgroundWebviewState;
}

class BackgroundWebviewCubit extends Cubit<BackgroundWebviewState> {
  final DatabaseService dbService;
  final ExtractorBuilder extractorBuilder;
  late final WebViewController _controller;
  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;
  bool _isRunning = false;

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
            if (_pageLoadCompleter != null &&
                !_pageLoadCompleter!.isCompleted) {
              _pageLoadCompleter!.complete();
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'ExtractionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (_extractionCompleter != null &&
              !_extractionCompleter!.isCompleted) {
            _extractionCompleter!.complete(message.message);
          }
        },
      );
  }

  Future<void> prefetchNextChapters({
    required int bookId,
    required int currentChapter,
    int limit = 3,
  }) async {
    if (_isRunning) return;
    _isRunning = true;
    emit(
      state.copyWith(
        isPrefetching: true,
        activeBookId: bookId,
        errorMessage: null,
      ),
    );

    try {
      final nextChapters = await dbService.getNextChaptersWithoutContent(
        bookId,
        currentChapter,
        limit,
      );

      if (nextChapters.isEmpty) return;

      for (final chapter in nextChapters) {
        await _extractChapterContent(chapter);
      }
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    } finally {
      _isRunning = false;
      emit(state.copyWith(isPrefetching: false, activeBookId: null));
    }
  }

  Future<void> _loadUrl(String url) async {
    _pageLoadCompleter = Completer<void>();
    await _controller.loadRequest(Uri.parse(url));
    await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
    _pageLoadCompleter = null;
  }

  Future<void> _extractChapterContent(ChapterInfo chapter) async {
    final origin = Uri.parse(chapter.url).origin;
    const maxAttempts = 2;
    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt += 1;
      try {
        await _loadUrl(chapter.url);

        final dynamic chapterTreeRaw = await _controller
            .runJavaScriptReturningResult(minTreeExtFn);
        final String chapterTree = chapterTreeRaw as String;
        final chapterPrompt = buildChapterExtractionAIPrompt(chapterTree);

        final chapterLlmResponse = await extractorBuilder
            .buildChapterExtractorSelectors(
              origin,
              chapterPrompt,
              forceReload: attempt > 1,
            );

        final chapterExtractor = LlmService.extractJsonFromResponse(
          chapterLlmResponse,
          ChapterExtractor.fromJson,
        );

        final contentJs = generateContentExtractionJSPrompt(
          jsonEncode([chapter.url]),
          jsonEncode(chapterExtractor.contentSection),
        );

        _extractionCompleter = Completer<String>();
        await _controller.runJavaScript(contentJs);
        final contentResultString = await _extractionCompleter!.future.timeout(
          const Duration(minutes: 2),
        );
        final contentResponse = jsonDecode(contentResultString);

        if (contentResponse.containsKey('error')) {
          throw Exception(contentResponse['error']);
        }

        final extracted = (contentResponse['contents'] as List)
            .cast<List<dynamic>>();
        final contents = extracted
            .map((section) => section.map((e) => e.toString()).toList())
            .expand((e) => e)
            .toList();

        if (contents.isNotEmpty) {
          await dbService.saveChapterContent(chapter.id!, contents);
        }

        return;
      } catch (error) {
        if (attempt >= maxAttempts) {
          print('Prefetch failed for ${chapter.url}: $error');
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }
}
