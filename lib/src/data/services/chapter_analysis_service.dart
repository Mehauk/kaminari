import 'package:jp_transliterate/jp_transliterate.dart'; // Ensure this is imported
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

class EntryAnalysisModel {
  final String word;
  final DictionaryEntry entry;
  final int count;

  EntryAnalysisModel({
    required this.word,
    required this.entry,
    required this.count,
  });
}

class ChapterAnalysisService {
  static Future<List<EntryAnalysisModel>> analyzeChapter(
    ChapterInfo chapter,
  ) async {
    if (chapter.content == null || chapter.content!.isEmpty) return [];

    final String fullText = chapter.content!.join(" ");
    final List<String> tokens = await KanjiService.tokenizeText(fullText);

    final Map<String, int> frequencies = {};
    for (var token in tokens) {
      final t = token.trim();
      if (!_isReviewWorthy(t)) continue;
      frequencies[t] = (frequencies[t] ?? 0) + 1;
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 15 most frequent unique words
    final topTokens = sorted.take(100).toList();

    List<EntryAnalysisModel> results = [];
    for (var item in topTokens) {
      final (wordMap, kanjis) = await KanjiService.lookupToken(item.key);
      results.add(
        EntryAnalysisModel(
          word: item.key,
          count: item.value,
          entry: DictionaryEntry(wordMap, kanjis: kanjis),
        ),
      );
    }
    return results;
  }

  static bool _isReviewWorthy(String text) {
    if (text.isEmpty) return false;

    bool hasKanji = JpTransliterate.isKanji(
      input: text,
      confidenceThreshold: 1 / (text.length + 1),
    );

    return hasKanji;
  }
}
