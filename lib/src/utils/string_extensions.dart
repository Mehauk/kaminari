import 'package:jp_transliterate/jp_transliterate.dart';

extension Capitalize on String {
  String get capitalize {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

extension Similarity on String {
  /// Returns a similarity score between 0.0 and 1.0.
  /// [isUrl] will prioritize the beginning of the string (domain/scheme)
  /// more heavily than the end (parameters/slugs).
  double similarity(String other, [bool isUrl = false]) {
    if (this == other) return 1.0;
    if (isEmpty || other.isEmpty) return 0.0;

    String s1 = isUrl ? toLowerCase().trim() : this;
    String s2 = other.toLowerCase().trim();

    // 1. Get Bigrams (pairs of characters)
    // Using bigrams is faster and allows for "fuzzy" partial matches
    Set<String> bigrams1 = _getBigrams(s1);
    Set<String> bigrams2 = _getBigrams(s2);

    int intersect = 0;

    // 2. Weighting logic
    // We iterate through the bigrams and apply a multiplier if it's a URL
    // and the bigram is located in the first 30% of the string.
    for (var b in bigrams1) {
      if (bigrams2.contains(b)) {
        double weight = 1.0;
        if (isUrl) {
          // Apply higher weight to the beginning of the URL
          int index = s1.indexOf(b);
          if (index < s1.length * 0.3) {
            weight = 2.0;
          }
        }
        intersect += weight.toInt();
      }
    }

    return (2.0 * intersect) / (bigrams1.length + bigrams2.length);
  }

  Set<String> _getBigrams(String s) {
    Set<String> bigrams = {};
    for (int i = 0; i < s.length - 1; i++) {
      bigrams.add(s.substring(i, i + 2));
    }
    return bigrams;
  }
}

extension IsPunctuation on String {
  bool get containsPunctuation =>
      RegExp(r'[^\p{L}\p{N}\p{Z}]', unicode: true).hasMatch(this);
}

extension JLPTEstimator on String {
  double calculateJapaneseDifficulty() {
    if (isEmpty) return 0.0;

    int totalKana = 0;
    int totalKanji = 0;
    double accumulatedKanjiComplexity = 0.0;

    int currentKanjiRun = 0;
    int kanjiRunCount = 0;

    // Always iterate CJK using .runes to safely handle 32-bit Unicode
    for (final int rune in runes) {
      final bool isKana = (rune >= 0x3040 && rune <= 0x30FF);
      final bool isKanji =
          (rune >= 0x4E00 && rune <= 0x9FFF) || // Standard CJK
          (rune >= 0x3400 && rune <= 0x4DBF) || // Extension A
          rune == 0x3005; // '々' iteration mark

      if (isKanji) {
        totalKanji++;
        accumulatedKanjiComplexity += _getKanjiComplexity(rune);

        if (currentKanjiRun == 0) kanjiRunCount++;
        currentKanjiRun++;
      } else if (isKana) {
        totalKana++;
        currentKanjiRun = 0;
      } else {
        // Punctuation, spaces, or Latin chars break a run,
        // but don't inflate the Japanese character count.
        currentKanjiRun = 0;
      }
    }

    final int totalJapaneseChars = totalKanji + totalKana;
    if (totalJapaneseChars == 0) return 0.0;

    // 1. Density Score (0.0 - 5.0)
    final double densityScore = (totalKanji / totalJapaneseChars) * 5.0;

    // 2. Complexity Score (0.0 - 3.0)
    final double avgComplexity = totalKanji > 0
        ? (accumulatedKanjiComplexity / totalKanji)
        : 0.0;
    final double complexityScore = avgComplexity * 3.0;

    // 3. Clustering Penalty (0.0 - 2.0)
    double clusteringScore = 0.0;
    if (totalKanji > 0 && kanjiRunCount > 0) {
      final double avgRunLength = totalKanji / kanjiRunCount;
      // Map an avg run of 1.0 -> 0pts, and an avg run of 5.0+ -> 2pts
      clusteringScore = ((avgRunLength - 1.0) / 4.0).clamp(0.0, 1.0) * 2.0;
    }

    final double rawScore = densityScore + complexityScore + clusteringScore;

    // Round to 1 decimal place and clamp to strict [0.0, 10.0]
    return (rawScore.clamp(0.0, 10.0) * 10).round() / 10;
  }

  double _getKanjiComplexity(int rune) {
    if (rune == 0x3005) return 0.05; // '々' is visually simple
    if (rune < 0x4E00) return 0.85; // Extension A characters are rare/archaic

    const int blockStart = 0x4E00; // '一'
    const int blockEnd = 0x9FFF;

    double normalized = (rune - blockStart) / (blockEnd - blockStart);
    return normalized.clamp(0.0, 1.0);
  }

  Future<String> get jlptEstimate async {
    final String text = this;
    final sentences = text
        .split(RegExp(r'[。！？\n]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    double totalScore = 0;

    for (final sentence in sentences) {
      totalScore += await _scoreSentence(sentence);
    }

    final avg = totalScore / sentences.length;

    if (avg >= 3) {
      return 'N1';
    } else if (avg >= 2.0) {
      return 'N2';
    } else if (avg >= 1.0) {
      return 'N3';
    } else if (avg >= 0.5) {
      return 'N4';
    } else {
      return 'N5';
    }
  }

  Future<double> _scoreSentence(String sentence) async {
    double score = 0;

    // 2. Kanji density
    final chars = sentence.split('');

    int kanjiCount = 0;
    int katakanaCount = 0;

    for (final c in chars) {
      if (JpTransliterate.isKanji(input: c)) {
        kanjiCount++;
      } else if (JpTransliterate.isKatakana(input: c)) {
        katakanaCount++;
      }
    }

    final total = chars.length.clamp(1, 9999);

    final kanjiRatio = kanjiCount / total;
    final katakanaRatio = katakanaCount / total;

    // Higher kanji density → harder
    score += kanjiRatio * 4.0;

    // Heavy katakana often means easier LN/anime vocab
    score -= katakanaRatio * 0.5;

    // 3. Rare reading heuristic
    //
    // Harder words tend to have:
    // - longer readings
    // - irregular readings
    // - many-kanji compounds
    final words = await JpTransliterate.transliterateWords(kanji: sentence);

    for (final word in words) {
      final surface = word.kanji;
      final reading = word.hiragana;

      final kanjiChars = surface
          .split('')
          .where((c) => JpTransliterate.isKanji(input: c))
          .length;

      // multi-kanji compounds
      if (kanjiChars >= 3) {
        score += 0.5;
      } else if (kanjiChars == 2) {
        score += 0.2;
      }

      // long readings tend to correlate with harder vocab
      if (reading.length >= 6) {
        score += 0.4;
      }

      // jukujikun-ish heuristic:
      // short word with disproportionately long reading
      if (surface.length <= 2 && reading.length >= 5 && kanjiChars > 0) {
        score += 0.7;
      }
    }

    // 4. Grammar complexity proxies

    // lots of clauses
    final commas = '、'.allMatches(sentence).length;
    score += commas * 0.15;

    // formal/literary structures
    final advancedPatterns = [
      'における',
      'にもかかわらず',
      'ざるを得ない',
      'ことなく',
      'かねる',
      '次第',
      'ものの',
    ];

    for (final pattern in advancedPatterns) {
      if (sentence.contains(pattern)) {
        score += 1.0;
      }
    }

    return score;
  }
}
