import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/constants/prompt.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/data/services/webview_extension_service.dart';
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
    @Default('') String origin,
    @Default('Loading...') String title,
    @Default(true) bool isLoading,
    @Default(ImportStatus.notImported) ImportStatus importStatus,
    DictionaryEntry? selectedEntry,
    @Default(0.0) double importProgress,
    @Default('') String progressMessage,
    BookDetails? previewBook,
    @Default({}) Set<String> unpinnedFields,
    @Default('ja') String language,
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  final ExtractorBuilder extractorBuilder;
  final BackgroundWebviewCubit backgroundWebviewCubit;
  final AppSettings appSettings;

  late final WebviewExtensionService _extensionService;
  WebViewController controller = WebViewController();
  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  BookDetailsExtractor? _lastSelectors;
  String? _lastFailedUrl;
  String? _lastSuccessfulPaginationUrl;

  bool get showMissingChapters => _lastFailedUrl != null;
  bool get hasSelectors => _lastSelectors != null;

  WebviewCubit({
    required this.extractorBuilder,
    required this.backgroundWebviewCubit,
    required this.appSettings,
    String? initialUrl,
  }) : super(const WebviewState()) {
    _extensionService = WebviewExtensionService(appSettings);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF15130B)) // Prevents initial flash
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            final blockPatterns = [
              'doubleclick.net',
              'googleads',
              'googlesyndication',
              'pagead',
              'adservice',
              'analytics.google.com',
              'adnxs',
              'amazon-adsystem',
              'criteo.com',
              'pubmatic.com',
              'rubiconproject.com',
              'popads',
              'popunder',
              'trafficjunky',
              'ad-score',
              'exoclick',
              'mgid.com',
              'outbrain',
              'taboola',
              'adcolony',
              'applovin',
              'unityads',
            ];
            if (blockPatterns.any((pattern) => url.contains(pattern))) {
              print(
                '[Kaminari-Adblock] Intercepted navigation to ad host: ${request.url}',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onProgress: (progress) {
            // Apply high-priority dark styling while parsing to eliminate white screen flashes
            _extensionService.applyEarlyDarkStyle(controller);
          },
          onPageStarted: (url) {
            // Force dark stylesheet immediately as DOM parsing begins
            _extensionService.applyEarlyDarkStyle(controller);
            _extensionService.applyExtensions(controller);

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

            // Apply loaded plugins / CDN structures
            await _extensionService.applyExtensions(controller);

            // Detect document language programmatically
            String docLang = 'en';
            try {
              final dynamic
              langRaw = await controller.runJavaScriptReturningResult(
                "document.documentElement.lang || document.querySelector('meta[http-equiv=\"content-language\"]')?.content || document.querySelector('meta[name=\"language\"]')?.content || document.querySelector('meta[name=\"lang\"]')?.content || 'en'",
              );
              final String parsed =
                  (langRaw is String ? jsonDecode(langRaw) : langRaw.toString())
                      .trim()
                      .toLowerCase();
              if (parsed.isNotEmpty) {
                docLang = parsed;
              }
            } catch (e) {
              print('[WebviewCubit] Failed to detect language: $e');
            }

            updateNavigation(
              url: url,
              title: title,
              isLoading: false,
              language: docLang,
            );
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

  /// Evaluates active document properties to confirm Cloudflare bypass
  /// and SPA paint cycles before resolving the load flow.
  Future<void> _waitForPageToSettle() async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < const Duration(seconds: 15)) {
      try {
        final dynamic isChallengeRaw = await controller
            .runJavaScriptReturningResult('''
          (function() {
            const text = document.body ? document.body.textContent : "";
            const title = document.title || "";
            
            // Checks standard signatures of Cloudflare, DDoS protection, or Turnstile frames
            const isCloudflare = 
              title.includes("Just a moment") || 
              title.includes("DDoS") ||
              title.includes("Cloudflare") ||
              document.querySelector("#challenge-running") !== null ||
              document.querySelector("#challenge-stage") !== null ||
              document.querySelector("#cf-wrapper") !== null ||
              text.includes("Checking your browser") ||
              text.includes("Checking if the site connection is secure");
              
            // Checks if the client-side JavaScript has not completed rendering the core layout shell
            const isStillLoading = !document.body || text.trim().length < 100;
            
            return isCloudflare || isStillLoading;
          })()
        ''');

        final String rawResult = isChallengeRaw
            .toString()
            .replaceAll('"', '')
            .trim()
            .toLowerCase();
        final bool isWaiting = rawResult == "true" || rawResult == "1";

        if (!isWaiting) {
          print("[WebViewCubit] Target page settled successfully.");
          // Provides a tiny frame buffer for visual elements to complete painting
          await Future.delayed(const Duration(milliseconds: 300));
          return;
        }

        print(
          "[WebViewCubit] Cloudflare challenge or loading shell detected. Waiting for redirect...",
        );
      } catch (e) {
        print(
          "[WebViewCubit] DOM state temporarily inaccessible (navigating): $e",
        );
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    print("[WebViewCubit] Settle loop reached maximum threshold; proceeding.");
  }

  void togglePinField(String field) {
    final updated = Set<String>.from(state.unpinnedFields);
    if (updated.contains(field)) {
      updated.remove(field);
    } else {
      updated.add(field);
    }
    emit(state.copyWith(unpinnedFields: updated));
  }

  void clearSelection() {
    _clearHighlights();
    emit(state.copyWith(selectedEntry: null));
  }

  void onWordFound(String message) async {
    // Prevent dictionary lookups when the current web document is English
    if (state.language.toLowerCase().startsWith('en')) {
      return;
    }

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

        let touchStartX = 0;
        let touchStartY = 0;
        let touchStartTime = 0;

        document.addEventListener('touchstart', function(e) {
          if (e.touches.length === 1) {
            touchStartX = e.touches[0].clientX;
            touchStartY = e.touches[0].clientY;
            touchStartTime = new Date().getTime();
          }
        }, {passive: true});

        document.addEventListener('touchend', function(e) {
          if (e.changedTouches.length === 1) {
            const touchEndX = e.changedTouches[0].clientX;
            const touchEndY = e.changedTouches[0].clientY;
            const touchEndTime = new Date().getTime();

            const dx = touchEndX - touchStartX;
            const dy = touchEndY - touchStartY;
            const distance = Math.sqrt(dx * dx + dy * dy);
            const duration = touchEndTime - touchStartTime;

            // Check if the interaction is a quick tap with minimal movement (not a swipe/scroll)
            if (distance < 10 && duration < 250) {
              const range = document.caretRangeFromPoint(touchEndX, touchEndY);
              
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
          }
        }, {passive: true});
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
    emit(
      state.copyWith(
        url: url,
        isLoading: true,
        importStatus: ImportStatus.notImported,
        selectedEntry: null,
        previewBook: null,
        importProgress: 0.0,
        progressMessage: '',
        unpinnedFields: {},
        language: 'ja',
      ),
    );
  }

  void updateNavigation({
    String? url,
    String? title,
    bool? isLoading,
    String? language,
  }) {
    emit(
      state.copyWith(
        url: url ?? state.url,
        title: title ?? state.title,
        isLoading: isLoading ?? state.isLoading,
        language: language ?? state.language,
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

  void invertPreviewChapters() {
    if (state.previewBook != null) {
      final reversedChapters = state.previewBook!.chapters.reversed.toList();
      final renumberedChapters = List<ChapterInfo>.generate(
        reversedChapters.length,
        (i) => reversedChapters[i].copyWith(number: i),
      );
      emit(
        state.copyWith(
          previewBook: state.previewBook!.copyWith(
            chapters: renumberedChapters,
          ),
        ),
      );
    }
  }

  void cancelImport() {
    _lastSelectors = null;
    _lastFailedUrl = null;
    _lastSuccessfulPaginationUrl = null;
    emit(
      state.copyWith(
        importStatus: ImportStatus.notImported,
        previewBook: null,
        importProgress: 0.0,
        progressMessage: '',
        unpinnedFields: {},
      ),
    );
  }

  void hideOverlay() {
    emit(state.copyWith(importStatus: ImportStatus.notImported));
  }

  Map<String, String> _buildAvoidSelectorsList({
    bool retryingChapters = false,
  }) {
    if (_lastSelectors == null) return {};

    final avoid = <String, String>{};
    final last = _lastSelectors!;
    print("last:$last");

    // 1. Chapter and Pagination retry
    if (retryingChapters) {
      if (last.nextPageUrl != null &&
          last.nextPageUrl!.isNotEmpty &&
          last.nextPageUrl!.toLowerCase() != "n/a") {
        avoid['nextPageUrl'] = last.nextPageUrl!.split(" ").join(",");
      }
      // avoid['individualChapterDetails.base'] =
      //     last.individualChapterDetails.base;
      // avoid['individualChapterDetails.url'] = last.individualChapterDetails.url;
      // avoid['individualChapterDetails.title'] =
      //     last.individualChapterDetails.title;
    }

    // 2. Unlocked / Unpinned metadata fields when clicking "Fix Incorrect Data"
    if (state.unpinnedFields.contains('title') && last.title.isNotEmpty) {
      avoid['title'] = last.title;
    }
    if (state.unpinnedFields.contains('author') && last.author.isNotEmpty) {
      avoid['author'] = last.author;
    }
    if (state.unpinnedFields.contains('synopsis') && last.synopsis.isNotEmpty) {
      avoid['synopsis'] = last.synopsis;
    }
    if (state.unpinnedFields.contains('coverUrl') &&
        last.coverUrl != null &&
        last.coverUrl!.isNotEmpty &&
        last.coverUrl!.toLowerCase() != 'n/a') {
      avoid['coverUrl'] = last.coverUrl!;
    }
    if (state.unpinnedFields.contains('jlptLevel') &&
        last.jlptLevel != null &&
        last.jlptLevel!.isNotEmpty &&
        last.jlptLevel!.toLowerCase() != 'n/a') {
      avoid['jlptLevel'] = last.jlptLevel!;
    }

    return avoid;
  }

  Future<void> handleImport({bool forceReload = false}) async {
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

    final previousBook = state.previewBook;

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
      await _waitForPageToSettle();
      final startingUrl = (await controller.currentUrl()) ?? state.url;
      final originResult = await controller.runJavaScriptReturningResult(
        "(function() {return document.location.origin;})()",
      );

      origin = originResult is String
          ? jsonDecode(originResult) as String
          : originResult.toString();

      emit(
        state.copyWith(
          origin: origin,
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

      final avoid = _buildAvoidSelectorsList();
      final prompt = buildDiscoveryAIPrompt(miniTree, avoidSelectors: avoid);

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

      var selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      if (_lastSelectors != null) {
        selectors = selectors.copyWith(
          title: !state.unpinnedFields.contains('title')
              ? _lastSelectors!.title
              : selectors.title,
          author: !state.unpinnedFields.contains('author')
              ? _lastSelectors!.author
              : selectors.author,
          synopsis: !state.unpinnedFields.contains('synopsis')
              ? _lastSelectors!.synopsis
              : selectors.synopsis,
          coverUrl: !state.unpinnedFields.contains('coverUrl')
              ? _lastSelectors!.coverUrl
              : selectors.coverUrl,
          jlptLevel: !state.unpinnedFields.contains('jlptLevel')
              ? _lastSelectors!.jlptLevel
              : selectors.jlptLevel,
          individualChapterDetails: !state.unpinnedFields.contains('chapters')
              ? _lastSelectors!.individualChapterDetails
              : selectors.individualChapterDetails,
          nextPageUrl: !state.unpinnedFields.contains('chapters')
              ? _lastSelectors!.nextPageUrl
              : selectors.nextPageUrl,
        );
      }

      _lastSelectors = selectors;

      var bookData = await _extractBookMetadata(selectors);

      if (previousBook != null) {
        bookData = bookData.copyWith(
          title: !state.unpinnedFields.contains('title')
              ? previousBook.title
              : bookData.title,
          author: !state.unpinnedFields.contains('author')
              ? previousBook.author
              : bookData.author,
          synopsis: !state.unpinnedFields.contains('synopsis')
              ? previousBook.synopsis
              : bookData.synopsis,
          coverUrl: !state.unpinnedFields.contains('coverUrl')
              ? previousBook.coverUrl
              : bookData.coverUrl,
          jlptLevel: !state.unpinnedFields.contains('jlptLevel')
              ? previousBook.jlptLevel
              : bookData.jlptLevel,
          chapters: !state.unpinnedFields.contains('chapters')
              ? previousBook.chapters
              : bookData.chapters,
        );
      }

      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _waitForPageToSettle();
        await _injectScanner();
      }

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Extraction parsed successfully.",
          previewBook: bookData,
          unpinnedFields: {},
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

  Future<void> handleImportMetadata() async {
    if (state.previewBook == null) return;

    final previousBook = state.previewBook!;

    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.1,
        progressMessage: "Minifying web structure...",
      ),
    );

    String? origin;
    try {
      await _waitForPageToSettle();
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

      final avoid = _buildAvoidSelectorsList();
      final prompt = buildDiscoveryAIPrompt(miniTree, avoidSelectors: avoid);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
        forceReload: true,
      );

      var selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      if (_lastSelectors != null) {
        selectors = selectors.copyWith(
          title: !state.unpinnedFields.contains('title')
              ? _lastSelectors!.title
              : selectors.title,
          author: !state.unpinnedFields.contains('author')
              ? _lastSelectors!.author
              : selectors.author,
          synopsis: !state.unpinnedFields.contains('synopsis')
              ? _lastSelectors!.synopsis
              : selectors.synopsis,
          coverUrl: !state.unpinnedFields.contains('coverUrl')
              ? _lastSelectors!.coverUrl
              : selectors.coverUrl,
          jlptLevel: !state.unpinnedFields.contains('jlptLevel')
              ? _lastSelectors!.jlptLevel
              : selectors.jlptLevel,
          individualChapterDetails: _lastSelectors!.individualChapterDetails,
          nextPageUrl: _lastSelectors!.nextPageUrl,
        );
      }

      _lastSelectors = selectors;

      emit(
        state.copyWith(
          importProgress: 0.8,
          progressMessage: "Extracting metadata from current page...",
          unpinnedFields: {},
        ),
      );

      final String metadataJs =
          """
        (async () => {
          try {
            const selectors = ${jsonEncode(selectors.toJson())};

            function safeQuery(root, sel) {
              if (!root || !sel || typeof sel !== 'string') return null;
              const s = sel.trim();
              if (!s || s === 'null' || s.toLowerCase() === 'n/a' || s.toLowerCase() === 'none') return null;
              try {
                const containsMatch = s.match(/^(.*?):contains\\(['"]?(.*?)['"]?\\)(.*)\$/i);
                if (containsMatch) {
                  const base = (containsMatch[1] + containsMatch[3]).trim() || '*';
                  const text = containsMatch[2].trim().toLowerCase();
                  const elements = root.querySelectorAll(base);
                  for (const el of elements) {
                    if (el.textContent && el.textContent.toLowerCase().includes(text)) {
                      return el;
                    }
                  }
                  return null;
                }
                return root.querySelector(s);
              } catch (e) {
                console.warn("[JS-Metadata] safeQuery error for " + s + ":", e);
                return null;
              }
            }

            const titleEl = safeQuery(document, selectors.title);
            const authorEl = safeQuery(document, selectors.author);
            const synopsisEl = safeQuery(document, selectors.synopsis);
            const coverEl = safeQuery(document, selectors.coverUrl);
            const jlptEl = safeQuery(document, selectors.jlptLevel);
            
            let coverUrl = '';
            if (coverEl) {
              coverUrl = coverEl.src || coverEl.getAttribute('data-src') || coverEl.href || coverEl.textContent.trim();
            }

            let jlptLevel = jlptEl ? jlptEl.textContent.trim() : '';

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

      if (title.isEmpty) title = previousBook.title;
      if (author.isEmpty) author = previousBook.author;
      if (synopsis.isEmpty) synopsis = previousBook.synopsis;

      if (previousBook.language == "ja" &&
          (jlptLevel == null || jlptLevel.isEmpty)) {
        jlptLevel = await synopsis.jlptEstimate;
      }

      final updatedBook = previousBook.copyWith(
        title: !state.unpinnedFields.contains('title')
            ? previousBook.title
            : title,
        author: !state.unpinnedFields.contains('author')
            ? previousBook.author
            : author,
        synopsis: !state.unpinnedFields.contains('synopsis')
            ? previousBook.synopsis
            : synopsis,
        coverUrl: !state.unpinnedFields.contains('coverUrl')
            ? previousBook.coverUrl
            : ((coverUrl != null && coverUrl.isNotEmpty)
                  ? coverUrl
                  : previousBook.coverUrl),
        jlptLevel: !state.unpinnedFields.contains('jlptLevel')
            ? previousBook.jlptLevel
            : ((jlptLevel != null && jlptLevel.isNotEmpty)
                  ? jlptLevel
                  : previousBook.jlptLevel),
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Metadata refreshed.",
          previewBook: updatedBook,
          unpinnedFields: {},
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

  Future<void> handleImportChapters() async {
    if (state.previewBook == null) return;

    final originalMetadata = state.previewBook!;

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
      await _waitForPageToSettle();
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

      final avoid = _buildAvoidSelectorsList(retryingChapters: true);
      final prompt = buildDiscoveryAIPrompt(miniTree, avoidSelectors: avoid);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
        forceReload: true,
      );

      emit(
        state.copyWith(
          importProgress: 0.75,
          progressMessage:
              "Analyzing pages and compiling chapter directories...",
        ),
      );

      var selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      if (_lastSelectors != null) {
        selectors = selectors.copyWith(
          title: _lastSelectors!.title,
          author: _lastSelectors!.author,
          synopsis: _lastSelectors!.synopsis,
          coverUrl: _lastSelectors!.coverUrl,
          jlptLevel: _lastSelectors!.jlptLevel,
        );
      }

      _lastSelectors = selectors;

      final freshBook = await _extractBookMetadata(selectors);

      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _waitForPageToSettle();
        await _injectScanner();
      }

      final mergedBook = freshBook.copyWith(
        url: originalMetadata.url,
        title: originalMetadata.title,
        author: originalMetadata.author,
        synopsis: originalMetadata.synopsis,
        coverUrl: originalMetadata.coverUrl,
        jlptLevel: originalMetadata.jlptLevel,
        chapters: freshBook.chapters,
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Chapters refreshed.",
          previewBook: mergedBook,
          unpinnedFields: {},
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

  Future<void> resumeImport() async {
    if (state.previewBook == null || _lastSelectors == null) return;

    final originalMetadata = state.previewBook!;

    emit(
      state.copyWith(
        importStatus: ImportStatus.extracting,
        importProgress: 0.5,
        progressMessage: "Resuming chapter extraction...",
        previewBook: null,
      ),
    );

    try {
      await _waitForPageToSettle();
      final startingUrl = (await controller.currentUrl()) ?? state.url;
      final startUrl =
          _lastFailedUrl ??
          _lastSuccessfulPaginationUrl ??
          originalMetadata.url;

      final freshBook = await _extractBookMetadata(
        _lastSelectors!,
        existingChapters: originalMetadata.chapters,
        startUrl: startUrl,
      );

      final currentUrl = await controller.currentUrl();
      if (startingUrl.isNotEmpty && currentUrl != startingUrl) {
        _pageLoadCompleter = Completer<void>();
        await controller.loadRequest(Uri.parse(startingUrl));
        await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
        _pageLoadCompleter = null;
        await _waitForPageToSettle();
        await _injectScanner();
      }

      final mergedBook = freshBook.copyWith(
        url: originalMetadata.url,
        title: !state.unpinnedFields.contains('title')
            ? originalMetadata.title
            : freshBook.title,
        author: !state.unpinnedFields.contains('author')
            ? originalMetadata.author
            : freshBook.author,
        synopsis: !state.unpinnedFields.contains('synopsis')
            ? originalMetadata.synopsis
            : freshBook.synopsis,
        coverUrl: !state.unpinnedFields.contains('coverUrl')
            ? originalMetadata.coverUrl
            : freshBook.coverUrl,
        jlptLevel: !state.unpinnedFields.contains('jlptLevel')
            ? originalMetadata.jlptLevel
            : freshBook.jlptLevel,
        chapters: freshBook.chapters,
        bookType: originalMetadata.bookType,
      );

      emit(
        state.copyWith(
          importStatus: ImportStatus.preview,
          importProgress: 1.0,
          progressMessage: "Resumed extraction parsed successfully.",
          previewBook: mergedBook,
          unpinnedFields: {},
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

      final bookId = await db.saveBook(bookData);

      final matchingBook = await db.getBook(bookId);

      if (matchingBook != null && matchingBook.id != null) {
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
    if (startUrl != null && startUrl.isNotEmpty) {
      print("[WebViewCubit] Loading index progression page: $startUrl");
      _pageLoadCompleter = Completer<void>();
      await controller.loadRequest(Uri.parse(startUrl));
      await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
      _pageLoadCompleter = null;
      await _waitForPageToSettle();
      await _injectScanner();
    }

    final initialIndex = existingChapters?.length ?? 0;

    final js = generateBookExtrationJSPrompt(selectors, initialIndex);

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

      String? currentFailedUrl = response['failedUrl'] as String?;
      String? currentLastSuccessfulUrl =
          response['lastSuccessfulUrl'] as String?;

      while (currentFailedUrl != null && currentFailedUrl.isNotEmpty) {
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

        await _waitForPageToSettle();
        await _injectScanner();

        final nextJs = generateBookExtrationJSPrompt(
          selectors,
          accumulatedChapters.length,
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

  void clearCachedExtractors() {
    extractorBuilder.clearCacheForOrigin(state.origin);
  }
}
