import 'dart:convert';

import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

class EntryAnalysisModel {
  final String word;
  final DictionaryEntry entry;
  final int count;

  EntryAnalysisModel({
    required this.word,
    required this.entry,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'count': count,
    'entry': entry.toJson(),
  };

  factory EntryAnalysisModel.fromJson(Map<String, dynamic> json) =>
      EntryAnalysisModel(
        word: json['word'],
        count: json['count'],
        entry: DictionaryEntry.fromCacheJson(json['entry']),
      );
}

class ChapterAnalysisService {
  static Future<int> getPrepCount(
    int bookId,
    ChapterInfo chapter,
    DatabaseService db,
  ) async {
    if (chapter.id == null) return 0;
    try {
      final cachedData = await db.getBookAnalysisCache(bookId, chapter.id!);
      if (cachedData != null) {
        final List decoded = jsonDecode(cachedData);
        return decoded.length;
      }
    } catch (_) {}
    return 100;
  }

  static Future<List<EntryAnalysisModel>> analyzeChapter(
    int bookId,
    ChapterInfo chapter, {
    required DatabaseService db,
  }) async {
    if (chapter.id == null) return [];

    // 1. Try to load from cache
    final cachedData = await db.getBookAnalysisCache(bookId, chapter.id!);
    if (cachedData != null) {
      final List decoded = jsonDecode(cachedData);
      return decoded.map((e) => EntryAnalysisModel.fromJson(e)).toList();
    }

    // 2. If no cache, perform expensive analysis
    if (chapter.content == null || chapter.content!.isEmpty) return [];

    final String fullText = chapter.content!.join(" ");
    final List<String> tokens = await KanjiService.tokenizeText(fullText);

    final Map<String, int> frequencies = {};
    for (var token in tokens) {
      final t = token.trim();
      if (!_isReviewWorthy(t)) continue;
      frequencies[t] = (frequencies[t] ?? 0) + 1;
    }

    // Compute the Priority Score for each token: Frequency * (1.0 + Difficulty)
    final Map<String, double> priorityScores = {};
    for (var entry in frequencies.entries) {
      final token = entry.key;
      final freq = entry.value;
      final difficulty = token.calculateJapaneseDifficulty();
      priorityScores[token] = freq * (1.0 + difficulty);
    }

    // Sort tokens descending based on Priority Score
    final sorted = frequencies.keys.toList()
      ..sort((a, b) => priorityScores[b]!.compareTo(priorityScores[a]!));

    final topTokens = sorted.take(100).toList();

    List<EntryAnalysisModel> results = [];
    for (var token in topTokens) {
      final (wordMap, kanjis) = await KanjiService.lookupToken(token);
      results.add(
        EntryAnalysisModel(
          word: token,
          count: frequencies[token]!, // Retain the real occurrence count for UI
          entry: DictionaryEntry(wordMap, kanjis: kanjis),
        ),
      );
    }

    // 3. Save results to cache for next time
    await db.saveBookAnalysisCache(
      bookId: bookId,
      chapterId: chapter.id!,
      jsonData: jsonEncode(results.map((e) => e.toJson()).toList()),
    );

    return results;
  }

  static bool _isReviewWorthy(String text) {
    if (text.isEmpty) return false;
    return JpTransliterate.isKanji(
      input: text,
      confidenceThreshold: 1 / (text.length + 1),
    );
  }
}
