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
