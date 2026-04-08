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
