import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/constants/prompt.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/globals/background_webview_cubit.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/utils/string_extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'import_webview_cubit.freezed.dart';

enum ImportStatus {
  notImported,
  extracting,
  preview,
  saving,
  success,
  failure;

  IconData get icon => switch (this) {
    ImportStatus.notImported => Icons.download_outlined,
    ImportStatus.extracting => Icons.downloading,
    ImportStatus.preview => Icons.preview_outlined,
    ImportStatus.saving => Icons.save_outlined,
    ImportStatus.success => Icons.download_done,
    ImportStatus.failure => Icons.cancel,
  };

  String get label => switch (this) {
    ImportStatus.notImported => "IMPORT",
    ImportStatus.extracting => "EXTRACTING",
    ImportStatus.preview => "CONFIRM",
    ImportStatus.saving => "SAVING",
    ImportStatus.success => "SUCCESS",
    ImportStatus.failure => "RETRY",
  };

  Color get color => switch (this) {
    ImportStatus.notImported => KaminariTheme.textTitle,
    ImportStatus.extracting => KaminariTheme.textPrimary,
    ImportStatus.preview => KaminariTheme.cyan,
    ImportStatus.saving => KaminariTheme.textPrimary,
    ImportStatus.success => KaminariTheme.success,
    ImportStatus.failure => KaminariTheme.error,
  };
}

@freezed
abstract class WebviewState with _$WebviewState {
  const factory WebviewState({
    @Default('') String url,
    @Default('Loading...') String title,
    @Default(true) bool isLoading,
    @Default(ImportStatus.notImported) ImportStatus importStatus,
    DictionaryEntry? selectedEntry,
    @Default(0.0) double importProgress,
    @Default('') String progressMessage,
    BookDetails? previewBook,
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  final ExtractorBuilder extractorBuilder;
  final BackgroundWebviewCubit backgroundWebviewCubit;
  WebViewController controller = WebViewController();
  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  WebviewCubit({
    required this.extractorBuilder,
    required this.backgroundWebviewCubit,
    String? initialUrl,
  }) : super(const WebviewState()) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            resetForNewPage(url);
            _injectScanner();
          },
          onPageFinished: (url) async {
            final title = await controller.getTitle();

            if (_pageLoadCompleter != null &&
                !_pageLoadCompleter!.isCompleted) {
              _pageLoadCompleter!.complete();
            }

            await _injectScanner();

            updateNavigation(url: url, title: title, isLoading: false);
          },
        ),
      )
      ..addJavaScriptChannel(
        'LookupChannel',
        onMessageReceived: (JavaScriptMessage message) {
          onWordFound(message.message);
        },
      )
      ..addJavaScriptChannel(
        'ExtractionChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (_extractionCompleter != null &&
              !_extractionCompleter!.isCompleted) {
            _extractionCompleter!.complete(message.message);
          }
        },
      )
      ..loadRequest(Uri.parse(initialUrl ?? 'https://syosetu.com/'));
  }

  void clearSelection() {
    _clearHighlights();
    emit(state.copyWith(selectedEntry: null));
  }

  void onWordFound(String message) async {
    final data = jsonDecode(message);
    final String fullText = data['text'];
    final int tapOffset = data['offset'];

    final tokens = await KanjiService.tokenizeText(fullText);

    String? targetedWord;
    int currentPos = 0;

    for (final token in tokens) {
      int tokenEnd = currentPos + token.length;

      if (tapOffset >= currentPos && tapOffset < tokenEnd) {
        targetedWord = token;
        break;
      }
      currentPos = tokenEnd;
    }

    if (targetedWord == null) return;

    final (wordMap, kanjis) = await KanjiService.lookupToken(targetedWord);

    emit(
      state.copyWith(selectedEntry: DictionaryEntry(wordMap, kanjis: kanjis)),
    );

    await _highlightWord(targetedWord);
  }

  Future<void> _injectScanner() async {
    await controller.runJavaScript(r'''
      (function() {
        if (window.__kaminariHighlightInstalled) return;
        window.__kaminariHighlightInstalled = true;

        const styleId = 'kaminari-word-highlight-style';
        if (!document.getElementById(styleId)) {
          const style = document.createElement('style');
          style.id = styleId;
          style.textContent = '.kaminari-word-highlight { background: rgba(255, 237, 59, 0.5); border-radius: 2px; }';
          document.head.appendChild(style);
        }

        window.kaminariClearHighlights = function() {
          const highlights = document.querySelectorAll('span.kaminari-word-highlight');
          highlights.forEach(function(span) {
            const parent = span.parentNode;
            if (!parent) return;
            while (span.firstChild) parent.insertBefore(span.firstChild, span);
            parent.removeChild(span);
            parent.normalize();
          });
        };

        window.kaminariHighlightWord = function(word) {
          if (!word || word.length === 0) return false;
          window.kaminariClearHighlights();

          const escaped = word.replace(/[.*+?^\${}()|[\\]\\]/g, '\\\$&');
          const useWordBoundaries = /^[A-Za-z0-9_]+$/.test(word);
          const regex = new RegExp(useWordBoundaries ? '\\b' + escaped + '\\b' : escaped);

          const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: function(node) {
              if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
              const parent = node.parentElement;
              if (!parent) return NodeFilter.FILTER_REJECT;
              if (parent.closest('script,style,noscript,iframe,textarea')) return NodeFilter.FILTER_REJECT;
              return NodeFilter.FILTER_ACCEPT;
            }
          });

          let currentNode;
          while (currentNode = walker.nextNode()) {
            const text = currentNode.nodeValue;
            const match = regex.exec(text);
            if (match) {
              const before = currentNode.splitText(match.index);
              const matched = before.splitText(match[0].length);
              const span = document.createElement('span');
              span.className = 'kaminari-word-highlight';
              span.textContent = before.nodeValue;
              matched.parentNode.replaceChild(span, before);
              return true;
            }
          }
          return false;
        };

        let lastTap = 0;

        document.addEventListener('touchstart', function(e) {
          const now = new Date().getTime();
          const timesince = now - lastTap;

          if (timesince < 300 && timesince > 0) {
            const touch = e.touches[0];
            const range = document.caretRangeFromPoint(touch.clientX, touch.clientY);
            
            if (range && range.startContainer.nodeType === Node.TEXT_NODE) {
              const container = range.startContainer;
              const offset = range.startOffset;
              
              const message = {
                "text": container.data.substring(offset),
                "offset": 0
              };
              
              if (window.LookupChannel) {
                window.LookupChannel.postMessage(JSON.stringify(message));
              }
            }
          }
          lastTap = now;
        }, {passive: false});
      })();
    ''');
  }

  Future<void> _clearHighlights() async {
    await controller.runJavaScript('''
      if (window.kaminariClearHighlights) {
        window.kaminariClearHighlights();
      }
    ''');
  }

  Future<void> _highlightWord(String word) async {
    await controller.runJavaScript('''
      if (window.kaminariHighlightWord) {
        window.kaminariHighlightWord(${jsonEncode(word)});
      }
    ''');
  }

  void resetForNewPage(String url) {
    emit(
      state.copyWith(
        url: url,
        isLoading: true,
        importStatus: .notImported,
        selectedEntry: null,
        previewBook: null,
        importProgress: 0.0,
        progressMessage: '',
      ),
    );
  }

  void updateNavigation({String? url, String? title, bool? isLoading}) {
    emit(
      state.copyWith(
        url: url ?? state.url,
        title: title ?? state.title,
        isLoading: isLoading ?? state.isLoading,
      ),
    );
  }

  void updatePreviewBookType(BookType type) {
    if (state.previewBook != null) {
      emit(
        state.copyWith(
          previewBook: state.previewBook!.copyWith(bookType: type),
        ),
      );
    }
  }

  void cancelImport() {
    emit(
      state.copyWith(
        importStatus: ImportStatus.notImported,
        previewBook: null,
        importProgress: 0.0,
        progressMessage: '',
      ),
    );
  }

  Future<void> handleImport({bool forceReload = false}) async {
    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.1,
        progressMessage: "Minifying web structure...",
        previewBook: null,
      ),
    );

    String? origin;
    try {
      final originResult = await controller.runJavaScriptReturningResult(
        "(function() {return document.location.origin;})()",
      );

      origin = originResult is String
          ? jsonDecode(originResult) as String
          : originResult.toString();

      emit(
        state.copyWith(
          importProgress: 0.3,
          progressMessage: "Extracting DOM tree context...",
        ),
      );

      final dynamic rawTree = await controller.runJavaScriptReturningResult(
        minTreeExtFn,
      );
      final String miniTree = rawTree as String;

      emit(
        state.copyWith(
          importProgress: 0.5,
          progressMessage: "Consulting AI for selector mapping...",
        ),
      );

      final prompt = buildDiscoveryAIPrompt(miniTree);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
        forceReload: forceReload,
      );

      emit(
        state.copyWith(
          importProgress: 0.75,
          progressMessage:
              "Analyzing pages and compiling chapter directories...",
        ),
      );

      final selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      final bookData = await _extractBookMetadata(selectors);

      print("${bookData.coverUrl}STUPIDO");

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Extraction parsed successfully.",
          previewBook: bookData,
        ),
      );
    } catch (e, stack) {
      print("Extraction Error: $e\n$stack");
      if (origin != null) {
        await extractorBuilder.clearCacheForOrigin(origin);
      }
      emit(
        state.copyWith(
          importStatus: ImportStatus.failure,
          progressMessage: "Extraction failed: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> confirmImport() async {
    if (state.previewBook == null) return;

    emit(
      state.copyWith(
        importStatus: ImportStatus.saving,
        importProgress: 0.9,
        progressMessage: "Saving entry into local SQL index...",
      ),
    );

    try {
      final bookData = state.previewBook!;
      final db = DatabaseService();
      await db.saveBook(bookData);

      final savedBooks = await db.getBooks();
      final matchingBook = savedBooks.firstWhere(
        (b) => b.title == bookData.title && b.source == bookData.source,
        orElse: () => bookData,
      );

      if (matchingBook.id != null) {
        final firstThree = matchingBook.chapters.take(3).toList();
        if (firstThree.isNotEmpty) {
          await backgroundWebviewCubit.enqueueChapters(
            bookId: matchingBook.id!,
            chapters: firstThree,
            isPriority: false,
          );
        }
      }

      emit(
        state.copyWith(
          importStatus: ImportStatus.success,
          importProgress: 1.0,
          progressMessage: "Successfully imported!",
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          importStatus: ImportStatus.failure,
          progressMessage: "Failed to persist book data: ${e.toString()}",
        ),
      );
    }
  }

  Future<BookDetails> _extractBookMetadata(
    BookDetailsExtractor selectors,
  ) async {
    final jsonMap = selectors.toJson();
    final reMap = {};

    final jsonCMap = selectors.individualChapterDetails.toJson();

    final nextPageSelector = jsonMap["nextPageUrl"] as String?;

    for (var ckey in jsonCMap.keys) {
      String selector = jsonCMap[ckey] ?? 'null';
      if (["null", "n/a", "none"].contains(selector.trim().toLowerCase())) {
        jsonCMap[ckey] = null;
      }
    }

    reMap["url"] = "document.location.href";
    reMap["source"] = "document.location.origin";
    reMap["language"] =
        "document.documentElement.lang || document.querySelector('meta[http-equiv=\"content-language\"]')?.content || document.querySelector('meta[name=\"language\"]')?.content || document.querySelector('meta[name=\"lang\"]')?.content || 'en'";
    for (var key in jsonMap.keys) {
      if (key == "url") {
        continue;
      } else if ([
        "individualChapterDetails",
        "nextPageUrl",
        "firstPageUrl",
      ].contains(key)) {
        continue;
      }

      String selector = jsonMap[key] ?? "null";
      if (["null", "n/a", "none"].contains(selector.trim().toLowerCase())) {
        continue;
      }

      if (key == "coverUrl") {
        reMap[key] =
            "(() => { const el = document.body.querySelector('$selector'); return el ? (el.src || el.getAttribute('data-src') || el.href || el.textContent.trim()) : ''; })()";
      } else {
        reMap[key] =
            "(() => { const el = document.body.querySelector('$selector'); return el ? el.textContent.trim() : ''; })()";
      }
    }

    final js = generateBookExtrationJSPrompt(
      reMap,
      chaptersLoadingIIFE(
        ChapterInfoExtractor.fromJson(jsonCMap),
        nextPageSelector ?? 'null',
      ),
    );

    _extractionCompleter = Completer<String>();
    await controller.runJavaScript(js);

    try {
      final resultString = await _extractionCompleter!.future.timeout(
        const Duration(minutes: 5),
      );

      final Map<String, dynamic> response = jsonDecode(resultString);

      if (response.containsKey('error')) {
        throw Exception("JS Extraction Error: ${response['error']}");
      }

      if (response['jlptLevel'] == null || response['jlptLevel'] == "") {
        response['jlptLevel'] =
            await (response['synopsis'] as String).jlptEstimate;
      }

      response['firstChapterCharCount'] = 0;
      final List chapters = response['chapters'] ?? [];
      response['chapters'] = chapters;

      final rawLanguage = (response['language'] as String?)?.trim();
      if (rawLanguage != null && rawLanguage.isNotEmpty) {
        response['language'] = rawLanguage
            .split(',')
            .first
            .trim()
            .toLowerCase();
      } else {
        response['language'] = 'en';
      }

      final book = BookDetails.fromJson(response);

      return book;
    } on TimeoutException {
      throw Exception("Extraction timed out after 5 minutes");
    } finally {
      _extractionCompleter = null;
    }
  }

  Map<String, Map<String, String>> getCachedExtractors() {
    return extractorBuilder.getCachedExtractors();
  }
}
