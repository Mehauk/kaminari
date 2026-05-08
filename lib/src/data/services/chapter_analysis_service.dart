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
  static Future<List<EntryAnalysisModel>> getCommonWords(
    ChapterInfo chapter,
  ) async {
    if (chapter.content == null || chapter.content!.isEmpty) return [];

    final String fullText = chapter.content!.join(" ");
    final List<String> tokens = await KanjiService.tokenizeText(fullText);

    final Map<String, int> frequencies = {};
    for (var token in tokens) {
      final t = token.trim();

      // NEW FILTER LOGIC:
      // Only keep the word if it contains at least one Kanji or is a Katakana word.
      if (!_isReviewWorthy(t)) continue;

      frequencies[t] = (frequencies[t] ?? 0) + 1;
    }

    // Sort by frequency and take top 15
    final sortedEntries = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTokens = sortedEntries.take(15).toList();

    List<EntryAnalysisModel> cards = [];
    for (var item in topTokens) {
      final (wordMap, kanjis) = await KanjiService.lookupToken(item.key);
      cards.add(
        EntryAnalysisModel(
          word: item.key,
          count: item.value,
          entry: DictionaryEntry(wordMap, kanjis: kanjis),
        ),
      );
    }

    return cards;
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
