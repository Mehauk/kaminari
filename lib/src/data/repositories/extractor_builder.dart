import 'package:kaminari/src/data/repositories/extractor_cache.dart';
import 'package:kaminari/src/data/services/llm_service.dart';

class ExtractorBuilder {
  final LlmService _llmService;
  final ExtractorCache _cache;

  ExtractorBuilder(this._llmService, this._cache);

  Future<String> buildBookExtractorSelectors(
    String origin,
    String prompt,
  ) async {
    String? fullResponse = await _cache.loadBookExtractorForOrigin(origin);
    if (fullResponse != null) return fullResponse;

    String fullResponse0 = '';
    await for (final chunk in _llmService.streamResponse(prompt)) {
      fullResponse0 += chunk;
    }

    _cache.saveBookExtractorForOrigin(origin, fullResponse0);
    return fullResponse0;
  }

  Future<String> buildChapterExtractorSelectors(
    String origin,
    String chapterPrompt,
  ) async {
    String? fullResponse = await _cache.loadPageExtractorForOrigin(origin);
    if (fullResponse != null) return fullResponse;

    String fullResponse0 = '';
    await for (final chunk in _llmService.streamResponse(chapterPrompt)) {
      fullResponse0 += chunk;
    }

    _cache.savePageExtractorForOrigin(origin, fullResponse0);
    return fullResponse0;
  }
}

// fullResponse0 =
//         '{"\$schema": "https://json-schema.org/draft/2020-12/schema", "title": ".p-novel__title", "author": ".p-novel__author > a", "coverUrl": "N/A", "jlptLevel": "N/A", "synopsis": "#novel_ex.p-novel__summary", "paginationFirstUrl": ".c-pager__item--first", "paginationNextUrl": ".c-pager__item--next", "chapter": ".p-eplist__sublist", "chapterDetails": {"url": "a.p-eplist__subtitle", "title": "a.p-eplist__subtitle", "updatedDate": ".p-eplist__update"}}';
   
    // chapterLlmResponse0 =
    //     '{"contentSection": "div.js-novel-text.p-novel__text"}';