import 'package:kaminari/src/data/repositories/extractor_cache.dart';
import 'package:kaminari/src/data/services/llm_service.dart';

class ExtractorBuilder {
  final LlmService _llmService;
  final ExtractorCache _cache;

  ExtractorBuilder(this._llmService, this._cache);

  Future<String> buildBookExtractorSelectors(
    String origin,
    String prompt, {
    bool forceReload = false,
  }) async {
    if (!forceReload) {
      String? fullResponse = await _cache.loadBookExtractorForOrigin(origin);
      print("book cache hit!: $fullResponse");
      if (fullResponse != null) return fullResponse;
    }

    String fullResponse0 = '';
    await for (final chunk in _llmService.streamResponse(prompt)) {
      fullResponse0 += chunk;
    }

    _cache.saveBookExtractorForOrigin(origin, fullResponse0);
    return fullResponse0;
  }

  Future<String> buildChapterExtractorSelectors(
    String origin,
    String chapterPrompt, {
    bool forceReload = false,
  }) async {
    if (!forceReload) {
      String? fullResponse = await _cache.loadPageExtractorForOrigin(origin);
      print("chapter cache hit!: $fullResponse");
      if (fullResponse != null) return fullResponse;
    }

    String fullResponse0 = '';
    await for (final chunk in _llmService.streamResponse(chapterPrompt)) {
      fullResponse0 += chunk;
    }

    _cache.savePageExtractorForOrigin(origin, fullResponse0);
    return fullResponse0;
  }

  Future<void> clearCacheForOrigin(String origin) =>
      _cache.clearCacheForOrigin(origin);

  /// Get all cached extractors for debug purposes
  Map<String, Map<String, String>> getCachedExtractors() =>
      _cache.getAllCachedExtractors();
}

// fullResponse0 =
//         '{"\$schema": "https://json-schema.org/draft/2020-12/schema", "title": ".p-novel__title", "author": ".p-novel__author > a", "coverUrl": "N/A", "jlptLevel": "N/A", "synopsis": "#novel_ex.p-novel__summary", "paginationFirstUrl": ".c-pager__item--first", "paginationNextUrl": ".c-pager__item--next", "chapter": ".p-eplist__sublist", "individualChapterDetails": {"url": "a.p-eplist__subtitle", "title": "a.p-eplist__subtitle", "updatedDate": ".p-eplist__update"}}';
   
    // chapterLlmResponse0 =
    //     '{"contentSections": "div.js-novel-text.p-novel__text"}';