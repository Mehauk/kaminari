import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/constants/javascript.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'import_webview_cubit.freezed.dart';

@freezed
abstract class WebviewState with _$WebviewState {
  const factory WebviewState({
    @Default('') String url,
    @Default('Loading...') String title,
    @Default(0.0) double progress,
    @Default(true) bool isLoading,
    @Default(false) bool canGoBack,
    @Default(false) bool canGoForward,
    @Default(false) bool isImporting,
    @Default(false) bool hasAppliedPadding,
    @Default(false) bool extractionFailed,
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  final LlmService llmService;
  WebViewController controller = WebViewController();

  WebviewCubit(String? initialUrl, this.llmService)
    : super(const WebviewState()) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            updateProgress(progress);

            if (progress >= 30 && !state.hasAppliedPadding) {
              setPaddingApplied(true); // Update Cubit immediately
              controller.runJavaScript(
                "document.body.style.paddingTop = '120px'",
              );
            }
          },
          onPageStarted: (url) => resetForNewPage(),
          onPageFinished: (url) async {
            // Re-apply on finish just in case the site cleared it
            controller.runJavaScript(
              "document.body.style.paddingTop = '120px'",
            );

            final title = await controller.getTitle();
            final canBack = await controller.canGoBack();
            final canForward = await controller.canGoForward();

            updateNavigation(
              back: canBack,
              forward: canForward,
              url: url,
              title: title,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl ?? 'https://syosetu.com/'));
  }

  void setExtractionFailed(bool failed) {
    emit(state.copyWith(extractionFailed: failed, isImporting: false));
  }

  void updateProgress(int progress) {
    emit(state.copyWith(progress: progress / 100, isLoading: progress < 100));
  }

  void setPaddingApplied(bool applied) {
    emit(state.copyWith(hasAppliedPadding: applied));
  }

  void resetForNewPage() {
    emit(
      state.copyWith(
        progress: 0,
        isLoading: true,
        hasAppliedPadding: false,
        extractionFailed: false,
      ),
    );
  }

  void updateNavigation({
    required bool back,
    required bool forward,
    String? url,
    String? title,
  }) {
    emit(
      state.copyWith(
        canGoBack: back,
        canGoForward: forward,
        url: url ?? state.url,
        title: title ?? state.title,
      ),
    );
  }

  void setImporting(bool importing) {
    emit(state.copyWith(isImporting: importing));
  }

  Future<void> handleImport() async {
    emit(state.copyWith(isImporting: true, extractionFailed: false));

    try {
      // 1. Extract Minified DOM via JS
      final dynamic rawTree = await controller.runJavaScriptReturningResult(
        minTreeExtFn,
      );
      final String miniTree = rawTree as String;

      // 2. Build Prompt
      final prompt = buildDiscoveryPrompt(miniTree);
      print(prompt);

      // 3. Get LLM Response (accumulate stream)
      // String fullResponse = "";
      // await for (final chunk in llmService.streamResponse(prompt)) {
      //   fullResponse += chunk;
      // }

      String fullResponse =
          '{"\$schema": "https://json-schema.org/draft/2020-12/schema", "title": ".p-novel__title", "author": ".p-novel__author > a", "coverUrl": "N/A", "jlptLevel": "N/A", "synopsis": "#novel_ex.p-novel__summary", "firstPageUrl": ".c-pager__item--first", "nextPageUrl": ".c-pager__item--next", "chapter": ".p-eplist__sublist", "chapterDetails": {"url": "a.p-eplist__subtitle", "title": "a.p-eplist__subtitle", "updatedDate": ".p-eplist__update"}}';

      // 4. Parse Selectors from JSON
      final selectors = _parseLlmJson(fullResponse);

      // 5. Use selectors to grab real data from the page
      final bookData = await _extractBookMetadata(selectors);

      // 6. Navigate to Details or Save to DB (Next step)
      print("Extracted Book: ${bookData.title}");
      emit(state.copyWith(isImporting: false));
    } on Error catch (e) {
      print("Extraction Error: $e\n${e.stackTrace}");
      emit(state.copyWith(isImporting: false, extractionFailed: true));
    }
  }

  BookDetailsExtractor _parseLlmJson(String response) {
    // Gemini often wraps JSON in markdown code blocks or adds conversational filler.
    // We attempt to extract the JSON block.
    try {
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = response.substring(startIndex, endIndex + 1);
        final jsonMap = Map<String, dynamic>.from(jsonDecode(jsonString));
        print("JSON: $jsonMap");
        return BookDetailsExtractor.fromJson(jsonMap);
      }

      // Fallback to previous logic if braces not found
      final cleanJson = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMap = Map<String, dynamic>.from(jsonDecode(cleanJson));
      return BookDetailsExtractor.fromJson(jsonMap);
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

    final js =
        """
      (async () => {
        const data = $reMap;
        data.chapters = await ${cheaptersLoadingIIFE(jsonMap["chapter"], selectors.chapterDetails, firstPageSelector, nextPageSelector)};
        return JSON.stringify(data);
      })()
    """;
    print("js");
    debugPrint(js);
    print("js");

    // Run a small JS script to grab text content using the discovered selectors
    final resultString = await controller.runJavaScriptReturningResult(js);

    print(resultString);
    // resultString is a String like "\"{\\\"title\\\": ...}\""
    // sometimes with extra quotes depending on the platform/WebView version
    final cleanJson = resultString
        .toString()
        .replaceAll(RegExp(r'^"|"$'), '')
        .replaceAll('\\"', '"');

    // Decode the string into a Map
    final Map<String, dynamic> response = jsonDecode(cleanJson);

    return BookDetails.fromJson(response);
  }
}
