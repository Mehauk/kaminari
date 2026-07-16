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

  BookDetailsExtractor? _lastSelectors;
  String? _lastFailedUrl;
  String? _lastSuccessfulPaginationUrl;
  int _pagesParsed = 0;

  /// Exposes a reactive boolean identifying if more than one page of chapters was successfully parsed.
  bool get showMissingChapters => _pagesParsed > 1;

  /// Identifies if the parser currently holds active selectors in memory.
  bool get hasSelectors => _lastSelectors != null;

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
            if (state.importStatus == ImportStatus.notImported) {
              resetForNewPage(url);
              _injectScanner();
            } else {
              updateNavigation(url: url, isLoading: true);
            }
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
      ..addJavaScriptChannel(
        'ProgressChannel',
        onMessageReceived: (JavaScriptMessage message) {
          onProgressUpdated(message.message);
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

  void onProgressUpdated(String message) {
    try {
      final data = jsonDecode(message);
      final int count = data['count'] ?? 0;
      emit(
        state.copyWith(
          progressMessage:
              "Analyzing pages and compiling chapter directories (found $count chapters)...",
        ),
      );
    } catch (e) {
      print("[ProgressChannel] Error parsing sequential progress: $e");
    }
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
    _lastSelectors = null;
    _lastFailedUrl = null;
    _lastSuccessfulPaginationUrl = null;
    _pagesParsed = 0;
    emit(
      state.copyWith(
        url: url,
        isLoading: true,
        importStatus: ImportStatus.notImported,
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
    _lastSelectors = null;
    _lastFailedUrl = null;
    _lastSuccessfulPaginationUrl = null;
    _pagesParsed = 0;
    emit(
      state.copyWith(
        importStatus: ImportStatus.notImported,
        previewBook: null,
        importProgress: 0.0,
        progressMessage: '',
      ),
    );
  }

  void hideOverlay() {
    emit(state.copyWith(importStatus: ImportStatus.notImported));
  }

  Future<void> handleImport({bool forceReload = false}) async {
    // Check if we can reopen a hidden preview on the same page (unless forcing a reload)
    if (!forceReload && state.previewBook != null) {
      final normCurrent = state.url.toLowerCase().trim().replaceAll(
        RegExp(r'/+$'),
        '',
      );
      final normPreview = state.previewBook!.url
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'/+$'), '');
      if (normCurrent == normPreview) {
        emit(state.copyWith(importStatus: ImportStatus.preview));
        return;
      }
    }

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
      final startingUrl = (await controller.currentUrl()) ?? state.url;
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

      _lastSelectors = selectors; // Save selectors for resuming later

      final bookData = await _extractBookMetadata(selectors);

      print("${bookData.coverUrl}STUPIDO");

      // Navigate back to the starting URL if the crawler moved us
      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _injectScanner();
      }

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
      if (_lastSelectors == null && origin != null) {
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

  /// Refetches only metadata selectors, reusing existing chapter selectors.
  Future<void> handleImportMetadata() async {
    if (state.previewBook == null) return;

    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.1,
        progressMessage: "Minifying web structure...",
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
          importProgress: 0.6,
          progressMessage: "Consulting AI for revised metadata selectors...",
        ),
      );

      final prompt = buildDiscoveryAIPrompt(miniTree);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
        forceReload: true, // Forces fresh AI selector generation
      );

      final selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      _lastSelectors = selectors;

      emit(
        state.copyWith(
          importProgress: 0.8,
          progressMessage: "Extracting metadata from current page...",
        ),
      );

      // Execute queries only for metadata fields on the current WebView frame
      final String metadataJs =
          """
        (async () => {
          try {
            const selectors = ${jsonEncode(selectors.toJson())};
            const titleEl = document.querySelector(selectors.title);
            const authorEl = document.querySelector(selectors.author);
            const synopsisEl = document.querySelector(selectors.synopsis);
            
            let coverUrl = '';
            if (selectors.coverUrl) {
              const coverEl = document.querySelector(selectors.coverUrl);
              if (coverEl) {
                coverUrl = coverEl.src || coverEl.getAttribute('data-src') || coverEl.href || coverEl.textContent.trim();
              }
            }

            let jlptLevel = '';
            if (selectors.jlptLevel) {
              const jlptEl = document.querySelector(selectors.jlptLevel);
              if (jlptEl) {
                jlptLevel = jlptEl.textContent.trim();
              }
            }

            const result = {
              "title": titleEl ? titleEl.textContent.trim() : '',
              "author": authorEl ? authorEl.textContent.trim() : '',
              "synopsis": synopsisEl ? synopsisEl.textContent.trim() : '',
              "coverUrl": coverUrl,
              "jlptLevel": jlptLevel
            };
            ExtractionChannel.postMessage(JSON.stringify(result));
          } catch (e) {
            ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
          }
        })()
      """;

      _extractionCompleter = Completer<String>();
      await controller.runJavaScript(metadataJs);

      final resultString = await _extractionCompleter!.future.timeout(
        const Duration(seconds: 30),
      );
      _extractionCompleter = null;

      final Map<String, dynamic> response = jsonDecode(resultString);
      if (response.containsKey('error')) {
        throw Exception("JS Metadata Query Failed: ${response['error']}");
      }

      String title = response['title'] ?? '';
      String author = response['author'] ?? '';
      String synopsis = response['synopsis'] ?? '';
      String? coverUrl = response['coverUrl'];
      String? jlptLevel = response['jlptLevel'];

      if (title.isEmpty) title = state.previewBook!.title;
      if (author.isEmpty) author = state.previewBook!.author;
      if (synopsis.isEmpty) synopsis = state.previewBook!.synopsis;

      if (state.previewBook!.language == "ja" &&
          (jlptLevel == null || jlptLevel.isEmpty)) {
        jlptLevel = await synopsis.jlptEstimate;
      }

      final updatedBook = state.previewBook!.copyWith(
        title: title,
        author: author,
        synopsis: synopsis,
        coverUrl: (coverUrl != null && coverUrl.isNotEmpty)
            ? coverUrl
            : state.previewBook!.coverUrl,
        jlptLevel: (jlptLevel != null && jlptLevel.isNotEmpty)
            ? jlptLevel
            : state.previewBook!.jlptLevel,
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Metadata refreshed.",
          previewBook: updatedBook,
        ),
      );
    } catch (e, stack) {
      print("Metadata Retry Error: $e\n$stack");
      emit(
        state.copyWith(
          importStatus: ImportStatus.failure,
          progressMessage: "Metadata retry failed: ${e.toString()}",
        ),
      );
    }
  }

  /// Re-runs the entire extraction process (including metadata and pagination) from scratch but preserves previously verified metadata.
  Future<void> handleImportChapters() async {
    if (state.previewBook == null) return;

    // Cache the verified metadata fields locally
    final originalMetadata = state.previewBook!;

    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.1,
        progressMessage: "Minifying web structure...",
        previewBook: null, // Loading indicator fallback
      ),
    );

    String? origin;
    try {
      final startingUrl = (await controller.currentUrl()) ?? state.url;
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
          progressMessage: "Consulting AI for revised selectors...",
        ),
      );

      final prompt = buildDiscoveryAIPrompt(miniTree);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
        forceReload: true, // Forces fresh AI selector generation
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

      _lastSelectors = selectors; // Save selectors for resuming later

      final freshBook = await _extractBookMetadata(selectors);

      // Navigate back to starting URL if crawler moved
      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _injectScanner();
      }

      // Merge: Overwrite freshBook's scraped metadata with the previously confirmed metadata
      final mergedBook = freshBook.copyWith(
        title: originalMetadata.title,
        author: originalMetadata.author,
        synopsis: originalMetadata.synopsis,
        coverUrl: originalMetadata.coverUrl,
        jlptLevel: originalMetadata.jlptLevel,
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Chapters refreshed.",
          previewBook: mergedBook,
        ),
      );
    } catch (e, stack) {
      print("Chapters Retry Error: $e\n$stack");
      emit(
        state.copyWith(
          importStatus: ImportStatus.failure,
          progressMessage: "Chapters retry failed: ${e.toString()}",
        ),
      );
    }
  }

  /// Continues pulling missing chapters starting from where the previous execution was interrupted, while preserving previously verified metadata.
  Future<void> resumeImport() async {
    if (state.previewBook == null || _lastSelectors == null) return;

    // Cache the verified metadata and chapters locally
    final originalMetadata = state.previewBook!;

    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.5,
        progressMessage: "Resuming chapter extraction...",
        previewBook: null, // Loading indicator fallback
      ),
    );

    try {
      final startingUrl = (await controller.currentUrl()) ?? state.url;
      // Prioritize the last failed URL, then the last successfully accessed URL, or fallback to original book URL
      final startUrl =
          _lastFailedUrl ??
          _lastSuccessfulPaginationUrl ??
          originalMetadata.url;

      final freshBook = await _extractBookMetadata(
        _lastSelectors!,
        existingChapters: originalMetadata.chapters,
        startUrl: startUrl,
      );

      // Navigate back to the starting URL if the crawler moved us
      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _injectScanner();
      }

      // Merge: Overwrite freshBook's scraped metadata with the previously confirmed metadata
      final mergedBook = freshBook.copyWith(
        title: originalMetadata.title,
        author: originalMetadata.author,
        synopsis: originalMetadata.synopsis,
        coverUrl: originalMetadata.coverUrl,
        jlptLevel: originalMetadata.jlptLevel,
        bookType: originalMetadata.bookType,
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Resumed extraction parsed successfully.",
          previewBook: mergedBook,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          importStatus: ImportStatus.failure,
          progressMessage: "Resumed extraction failed: ${e.toString()}",
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
    BookDetailsExtractor selectors, {
    List<ChapterInfo>? existingChapters,
    String? startUrl,
  }) async {
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

    // Reset pagination counter only on fresh runs
    if (existingChapters == null || existingChapters.isEmpty) {
      _pagesParsed = 0;
    }

    // If starting from a specific continuation URL, load it into the WebView first
    if (startUrl != null && startUrl.isNotEmpty) {
      print("[WebViewCubit] Loading index progression page: $startUrl");
      _pageLoadCompleter = Completer<void>();
      await controller.loadRequest(Uri.parse(startUrl));
      await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
      _pageLoadCompleter = null;
      await Future.delayed(const Duration(milliseconds: 1000));
      await _injectScanner();
    }

    final initialIndex = existingChapters?.length ?? 0;

    final js = generateBookExtrationJSPrompt(
      reMap,
      chaptersLoadingIIFE(
        ChapterInfoExtractor.fromJson(jsonCMap),
        nextPageSelector ?? 'null',
        initialIndex, // Pass our start index alignment
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

      List<dynamic> accumulatedChapters = List.from(
        existingChapters?.map((e) => e.toJson()) ?? [],
      );
      accumulatedChapters.addAll(response['chapters'] ?? []);

      _pagesParsed += (response['pagesParsed'] as num? ?? 0).toInt();

      String? currentFailedUrl = response['failedUrl'] as String?;
      String? currentLastSuccessfulUrl =
          response['lastSuccessfulUrl'] as String?;

      // Fast fetch failed (likely on a cross-origin transition page).
      // We navigate WebView sequentially to cross the domain boundary, extract,
      // and re-trigger fast fetch sequentially from the new loaded context.
      while (currentFailedUrl != null && currentFailedUrl.isNotEmpty) {
        // Sequential pacing to avoid webserver rate-limiting/DDoS alerts on hard navigations
        await Future.delayed(const Duration(milliseconds: 1200));

        print(
          "[WebViewCubit] Fast fetch failed. Resuming sequentially via WebView navigation to: $currentFailedUrl",
        );
        emit(
          state.copyWith(
            progressMessage:
                "Loading next domain context via WebView (found ${accumulatedChapters.length} chapters)...",
          ),
        );

        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(currentFailedUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;

        // Allow some time for layout elements to settle
        await Future.delayed(const Duration(milliseconds: 1000));
        await _injectScanner();

        // Re-run the fast fetch script *from the newly loaded domain's context*
        final nextJs = generateBookExtrationJSPrompt(
          reMap,
          chaptersLoadingIIFE(
            ChapterInfoExtractor.fromJson(jsonCMap),
            nextPageSelector ?? 'null',
            accumulatedChapters.length, // Resume fast index alignment
          ),
        );

        _extractionCompleter = Completer<String>();
        await controller.runJavaScript(nextJs);

        final nextResultString = await _extractionCompleter!.future.timeout(
          const Duration(minutes: 5),
        );
        _extractionCompleter = null;

        final Map<String, dynamic> nextResponse = jsonDecode(nextResultString);

        if (nextResponse.containsKey('error')) {
          throw Exception(
            "JS Extraction Error on resume: ${nextResponse['error']}",
          );
        }

        final List newChapters = nextResponse['chapters'] ?? [];
        accumulatedChapters.addAll(newChapters);
        _pagesParsed += (nextResponse['pagesParsed'] as num? ?? 0).toInt();

        // Update target failed URL (will continue in same-origin fetch unless it runs into a separate boundary)
        currentFailedUrl = nextResponse['failedUrl'] as String?;
        if (nextResponse['lastSuccessfulUrl'] != null) {
          currentLastSuccessfulUrl =
              nextResponse['lastSuccessfulUrl'] as String?;
        }
      }

      _lastFailedUrl = currentFailedUrl;
      _lastSuccessfulPaginationUrl = currentLastSuccessfulUrl;

      response['chapters'] = accumulatedChapters;
      response['firstChapterCharCount'] = 0;

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

      if (response['language'] == "ja" &&
          (response['jlptLevel'] == null || response['jlptLevel'] == "")) {
        response['jlptLevel'] =
            await (response['synopsis'] as String).jlptEstimate;
      }

      return book;
    } on TimeoutException {
      throw Exception("Extraction timed out.");
    } finally {
      _extractionCompleter = null;
      _pageLoadCompleter = null;
    }
  }

  Map<String, Map<String, String>> getCachedExtractors() {
    return extractorBuilder.getCachedExtractors();
  }
}
