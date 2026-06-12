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
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/utils/string_extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'import_webview_cubit.freezed.dart';

enum ImportStatus {
  notImported,
  importedSuccessfully,
  importing,
  importFailure;

  IconData get icon => switch (this) {
    ImportStatus.notImported => Icons.download_outlined,
    ImportStatus.importedSuccessfully => Icons.download_done,
    ImportStatus.importing => Icons.downloading,
    ImportStatus.importFailure => Icons.cancel,
  };

  String get label => switch (this) {
    ImportStatus.notImported => "IMPORT",
    ImportStatus.importedSuccessfully => "IMPORTED",
    ImportStatus.importing => "IMPORTING",
    ImportStatus.importFailure => "FAILED TO IMPORT",
  };

  Color get color => switch (this) {
    ImportStatus.notImported => KaminariTheme.textTitle,
    ImportStatus.importedSuccessfully => KaminariTheme.success,
    ImportStatus.importing => KaminariTheme.textPrimary,
    ImportStatus.importFailure => KaminariTheme.error,
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
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  final ExtractorBuilder extractorBuilder;
  WebViewController controller = WebViewController();
  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  WebviewCubit({required this.extractorBuilder, String? initialUrl})
    : super(const WebviewState()) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => resetForNewPage(url),
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

    // 1. Tokenize the entire context chunk
    final tokens = await KanjiService.tokenizeText(fullText);

    // 2. Find which token contains the tapOffset
    String? targetedWord;
    int currentPos = 0;

    for (final token in tokens) {
      int tokenEnd = currentPos + token.length;

      // Check if the tap happened within this token's boundaries
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

          // If the time between taps is less than 300ms, treat it as a double tap
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
            // Prevent zooming on double-tap if desired
            // e.preventDefault(); 
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

  Future<void> handleImport() async {
    emit(state.copyWith(importStatus: .importing));

    String? origin;
    try {
      final originResult = await controller.runJavaScriptReturningResult(
        "(function() {return document.location.origin;})()",
      );

      // runJavaScriptReturningResult returns a JSON-encoded string for string values,
      // so we need to decode it to remove the quotes
      origin = originResult is String
          ? jsonDecode(originResult) as String
          : originResult.toString();

      print("[WebviewCubit] Extracted origin: '$origin'");

      // 1. Extract Minified DOM via JS
      final dynamic rawTree = await controller.runJavaScriptReturningResult(
        minTreeExtFn,
      );
      final String miniTree = rawTree as String;

      // 2. Build Prompt
      final prompt = buildDiscoveryAIPrompt(miniTree);
      print(prompt);

      final fullResponse = await extractorBuilder.buildBookExtractorSelectors(
        origin,
        prompt,
      );

      // 4. Parse Selectors from JSON
      final selectors = LlmService.extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      // 5. Use selectors to grab real data from the page
      final bookData = await _extractBookMetadata(selectors);

      // 6. Save to DB
      print(
        "Extracted Book: ${bookData.title} with ${bookData.chapters.length} chapters",
      );
      await DatabaseService().saveBook(bookData);

      emit(state.copyWith(importStatus: .importedSuccessfully));
    } catch (e, stack) {
      print("Extraction Error: $e\n$stack");
      if (origin != null) extractorBuilder.clearCacheForOrigin(origin);
      emit(state.copyWith(importStatus: .importFailure));
    }
  }

  Future<BookDetails> _extractBookMetadata(
    BookDetailsExtractor selectors,
  ) async {
    final jsonMap = selectors.toJson();
    final reMap = {};

    final jsonCMap = selectors.individualChapterDetails.toJson();
    final reCMap = {};

    // final firstPageSelector = jsonMap["firstPageUrl"] as String;
    final nextPageSelector = jsonMap["nextPageUrl"] as String?;

    for (var ckey in jsonCMap.keys) {
      String selector = jsonCMap[ckey] ?? 'null';
      if (["null", "n/a", "none"].contains(selector.toLowerCase())) continue;

      if (ckey == "url") {
        reCMap[ckey] = "e.querySelector('$selector').href";
        continue;
      }

      reCMap[ckey] = "e.querySelector('$selector').textContent.trim()";
    }

    reCMap["number"] = "0";

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
      if (["null", "n/a", "none"].contains(selector.toLowerCase())) continue;

      reMap[key] =
          "document.body.querySelector('$selector').textContent.trim()";
    }

    final js = generateBookExtrationJSPrompt(
      reMap,
      cheaptersLoadingIIFE(
        selectors.individualChapterDetails,
        nextPageSelector ?? 'null',
      ),
    );

    print("js");
    debugPrint(js);
    print("js");

    // Run a small JS script to grab text content using the discovered selectors
    _extractionCompleter = Completer<String>();
    await controller.runJavaScript(js);

    try {
      final resultString = await _extractionCompleter!.future.timeout(
        const Duration(minutes: 5),
      );

      print(resultString);
      final Map<String, dynamic> response = jsonDecode(resultString);

      if (response.containsKey('error')) {
        throw Exception("JS Extraction Error: ${response['error']}");
      }

      // AI DO THIS:
      // navigate to first chapter
      // do chapter extraction prompt once
      // extract the first 3 chapters
      print("resultString");
      debugPrint(response.toString());

      final String extractedSource = response['source'] as String? ?? '';
      print(
        "[WebviewCubit] Extracted source from response: '$extractedSource'",
      );

      final List chapters = response['chapters'] ?? [];
      if (chapters.isNotEmpty) {
        final firstChapterUrl = chapters[0]['url'];
        if (firstChapterUrl != null) {
          // 1. Navigate to first chapter to find content selector
          _pageLoadCompleter = Completer<void>();
          await controller.loadRequest(Uri.parse(firstChapterUrl));
          await _pageLoadCompleter!.future.timeout(const Duration(seconds: 30));
          _pageLoadCompleter = null;

          // 2. Extract DOM tree of chapter page
          final dynamic chapterTreeRaw = await controller
              .runJavaScriptReturningResult(minTreeExtFn);
          final String chapterTree = chapterTreeRaw as String;

          // 3. Get selector from LLM
          final chapterPrompt = buildChapterExtractionAIPrompt(chapterTree);
          print("chapterpor");
          debugPrint(chapterPrompt);

          final chapterLlmResponse = await extractorBuilder
              .buildChapterExtractorSelectors(extractedSource, chapterPrompt);

          print('chapterLlmResponse');
          print(chapterLlmResponse);
          print('chapterLlmResponse');

          final chapterExtractor = LlmService.extractJsonFromResponse(
            chapterLlmResponse,
            ChapterExtractor.fromJson,
          );

          // 4. Use selector to fetch content for first 3 chapters
          final urlsToExtract = chapters
              .take(3)
              .map((c) => c['url'] as String)
              .toList();
          final contentJs = generateContentExtractionJSPrompt(
            jsonEncode(urlsToExtract),
            jsonEncode(chapterExtractor.contentSections),
          );

          _extractionCompleter = Completer<String>();
          await controller.runJavaScript(contentJs);
          final contentResultString = await _extractionCompleter!.future
              .timeout(const Duration(minutes: 2));
          final contentResponse = jsonDecode(contentResultString);

          if (contentResponse.containsKey('error')) {
            print("Content Extraction Error: ${contentResponse['error']}");
          } else {
            final List contents = contentResponse['contents'];
            for (int i = 0; i < contents.length; i++) {
              chapters[i]['content'] = List<String>.from(contents[i]);
            }
          }
        }
      }

      if (response['jlptLevel'] == null || response['jlptLevel'] == "") {
        response['jlptLevel'] =
            await (response['synopsis'] as String).jlptEstimate;
      }

      response['firstChapterCharCount'] = 0;
      if (chapters.isNotEmpty) {
        final firstChapter = Map<String, dynamic>.from(chapters[0]);
        if (firstChapter['content'] != null) {
          final contentSections = List<String>.from(firstChapter['content']);
          response['firstChapterCharCount'] = contentSections.join().length;
        }
      }

      debugPrint(chapters.first.toString());
      debugPrint(response['language']);

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

  /// Get all cached extractors for debug purposes
  Map<String, Map<String, String>> getCachedExtractors() {
    return extractorBuilder.getCachedExtractors();
  }
}
