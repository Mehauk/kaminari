import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/constants/prompt.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/extractor_cache.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
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
    @Default(false) bool hasAppliedPadding,
    @Default(ImportStatus.notImported) ImportStatus importStatus,
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  final LlmService llmService;
  final ExtractorCache extractorCache;
  WebViewController controller = WebViewController();
  Completer<String>? _extractionCompleter;
  Completer<void>? _pageLoadCompleter;

  WebviewCubit({
    required this.llmService,
    required this.extractorCache,
    String? initialUrl,
  }) : super(const WebviewState()) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress >= 30 && !state.hasAppliedPadding) {
              emit(state.copyWith(hasAppliedPadding: true));
              controller.runJavaScript(
                "document.body.style.paddingTop = '120px'",
              );
            }
          },
          onPageStarted: (_) => resetForNewPage(),
          onPageFinished: (url) async {
            controller.runJavaScript(
              "document.body.style.paddingTop = '120px'",
            );

            final title = await controller.getTitle();

            if (_pageLoadCompleter != null &&
                !_pageLoadCompleter!.isCompleted) {
              _pageLoadCompleter!.complete();
            }

            updateNavigation(url: url, title: title);
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
      )
      ..loadRequest(Uri.parse(initialUrl ?? 'https://syosetu.com/'));
  }

  void resetForNewPage() {
    emit(
      state.copyWith(
        isLoading: true,
        hasAppliedPadding: false,
        importStatus: .notImported,
      ),
    );
  }

  void updateNavigation({String? url, String? title}) {
    emit(state.copyWith(url: url ?? state.url, title: title ?? state.title));
  }

  Future<void> handleImport() async {
    emit(state.copyWith(importStatus: .importing));

    try {
      // 1. Extract Minified DOM via JS
      final dynamic rawTree = await controller.runJavaScriptReturningResult(
        minTreeExtFn,
      );
      final String miniTree = rawTree as String;

      // 2. Build Prompt
      final prompt = buildDiscoveryAIPrompt(miniTree);
      print(prompt);

      // 3. Get LLM Response (accumulate stream)
      // String fullResponse = "";
      // await for (final chunk in llmService.streamResponse(prompt)) {
      //   fullResponse += chunk;
      // }

      String fullResponse =
          '{"\$schema": "https://json-schema.org/draft/2020-12/schema", "title": ".p-novel__title", "author": ".p-novel__author > a", "coverUrl": "N/A", "jlptLevel": "N/A", "synopsis": "#novel_ex.p-novel__summary", "firstPageUrl": ".c-pager__item--first", "nextPageUrl": ".c-pager__item--next", "chapter": ".p-eplist__sublist", "chapterDetails": {"url": "a.p-eplist__subtitle", "title": "a.p-eplist__subtitle", "updatedDate": ".p-eplist__update"}}';

      // 4. Parse Selectors from JSON
      final selectors = _extractJsonFromResponse(
        fullResponse,
        BookDetailsExtractor.fromJson,
      );

      // 5. Use selectors to grab real data from the page
      final bookData = await _extractBookMetadata(selectors);

      // 6. Save to DB
      print("Extracted Book: ${bookData.title}");
      await DatabaseService().saveBook(bookData);

      emit(state.copyWith(importStatus: .importedSuccessfully));
    } catch (e, stack) {
      print("Extraction Error: $e\n$stack");
      emit(state.copyWith(importStatus: .importFailure));
    }
  }

  T _extractJsonFromResponse<T>(
    String response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // Gemini often wraps JSON in markdown code blocks or adds conversational filler.
    // We attempt to extract the JSON block.
    try {
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = response.substring(startIndex, endIndex + 1);
        final jsonMap = Map<String, dynamic>.from(jsonDecode(jsonString));
        print("JSON: $jsonMap");
        return fromJson(jsonMap);
      }

      // Fallback to previous logic if braces not found
      final cleanJson = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMap = Map<String, dynamic>.from(jsonDecode(cleanJson));
      return fromJson(jsonMap);
    } catch (e) {
      print("JSON Parsing Error: $e");
      print("Original Response: $response");
      rethrow;
    }
  }

  Future<BookDetails> _extractBookMetadata(
    BookDetailsExtractor selectors,
  ) async {
    final jsonMap = selectors.toJson();
    final reMap = {};

    final jsonCMap = selectors.chapterDetails.toJson();
    final reCMap = {};

    final firstPageSelector = jsonMap["firstPageUrl"] as String;
    final nextPageSelector = jsonMap["nextPageUrl"] as String;

    for (var ckey in jsonCMap.keys) {
      String selector = jsonCMap[ckey];
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
    for (var key in jsonMap.keys) {
      if (key == "url") {
        continue;
      } else if ([
        "chapterDetails",
        "nextPageUrl",
        "firstPageUrl",
      ].contains(key)) {
        continue;
      }

      String selector = jsonMap[key];
      if (["null", "n/a", "none"].contains(selector.toLowerCase())) continue;

      if (key == "chapter") {
        reMap["chapters"] = null;
      } else {
        reMap[key] =
            "document.body.querySelector('$selector').textContent.trim()";
      }
    }

    final js = generateBookExtrationJSPrompt(
      reMap,
      cheaptersLoadingIIFE(
        jsonMap["chapter"],
        selectors.chapterDetails,
        firstPageSelector,
        nextPageSelector,
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
          print(chapterPrompt);

          // String chapterLlmResponse = "";
          // await for (final chunk in llmService.streamResponse(chapterPrompt)) {
          //   chapterLlmResponse += chunk;
          // }

          final String chapterLlmResponse =
              '{"contentSection": "div.js-novel-text.p-novel__text"}';

          print('chapterLlmResponse');
          print(chapterLlmResponse);
          print('chapterLlmResponse');

          final chapterExtractor = _extractJsonFromResponse(
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
            jsonEncode(chapterExtractor.contentSection),
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

      final book = BookDetails.fromJson(response);

      print(book.chapters.first);

      return book;
    } on TimeoutException {
      throw Exception("Extraction timed out after 5 minutes");
    } finally {
      _extractionCompleter = null;
    }
  }
}
