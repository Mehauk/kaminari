import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/constants/javascript.dart';
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
      String fullResponse = "";
      await for (final chunk in llmService.streamResponse(prompt)) {
        fullResponse += chunk;
      }

      // 4. Parse Selectors from JSON
      final selectors = _parseLlmJson(fullResponse);

      // 5. Use selectors to grab real data from the page
      final bookData = await _extractBookMetadata(selectors);

      // 6. Navigate to Details or Save to DB (Next step)
      print("Extracted Book: ${bookData['title']}");
      emit(state.copyWith(isImporting: false));
    } catch (e) {
      print("Extraction Error: $e");
      emit(state.copyWith(isImporting: false, extractionFailed: true));
    }
  }

  Map<String, String> _parseLlmJson(String response) {
    // Gemini often wraps JSON in markdown code blocks or adds conversational filler.
    // We attempt to extract the JSON block.
    try {
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = response.substring(startIndex, endIndex + 1);
        print("Cleaned JSON: $jsonString");
        return Map<String, String>.from(jsonDecode(jsonString));
      }

      // Fallback to previous logic if braces not found
      final cleanJson = response.replaceAll(RegExp(r'```json|```'), '').trim();
      return Map<String, String>.from(jsonDecode(cleanJson));
    } catch (e) {
      print("JSON Parsing Error: $e");
      print("Original Response: $response");
      rethrow;
    }
  }

  Future<Map<String, String>> _extractBookMetadata(
    Map<String, String> selectors,
  ) async {
    // Run a small JS script to grab text content using the discovered selectors
    final results = await controller.runJavaScriptReturningResult("""
      (function() {
        return {
          title: document.querySelector('${selectors['title']}')?.innerText || '',
          author: document.querySelector('${selectors['author']}')?.innerText || '',
          synopsis: document.querySelector('${selectors['synopsis']}')?.innerText || '',
        };
      })()
    """);

    print(results);
    return Map<String, String>.from(results as Map);
  }
}
