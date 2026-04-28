import 'package:flutter/cupertino.dart';

@immutable
abstract class SoundsBase {
  // Can be overridden
  Iterable<T> map<T>(T Function(String e) toElement) sync* {
    for (String? element in toList()) {
      if (element != null) yield toElement(element.toUpperCase());
    }
  }

  // not to be changed by subclasses
  List<String?> toList() => toMap().values.toList();

  List<String> getKeys() => toMap().keys.toList();

  String? operator [](String index) => toMap()[index];

  @override
  String toString() => toMap().toString();

  // Need implementation
  Map<String, String?> toMap();
}

class KanaModel extends SoundsBase {
  final String? katakana;
  final String? hiragana;
  final String? sound;

  final int ord;
  final int difficulty;

  KanaModel(Map<String, Object?> map)
    : ord = map["ord"] as int,
      difficulty = map["hard"] as int,
      katakana = map["kata"] as String?,
      hiragana = map["hira"] as String?,
      sound = map["sound"] as String?;

  KanaModel copywith(String? hira, String? kata, String? sound, {int? ord}) {
    return KanaModel({
      "sound": sound,
      "kata": kata,
      "hira": hira,
      "ord": ord ?? this.ord,
      "hard": difficulty,
    });
  }

  @override
  Map<String, String?> toMap() {
    return {"sound": sound, "kata": katakana, "hira": hiragana};
  }

  @override
  bool operator ==(Object other) {
    return (other is KanaModel) && other.ord == ord;
  }

  KanaModel operator +(KanaModel other) {
    String eng = "";

    if ((sound ?? "").contains("**")) {
      eng =
          (sound ?? "").replaceFirst("**", "") +
          (other.sound?[0] ?? "") +
          (other.sound ?? "");
    } else {
      eng = (sound ?? "") + (other.sound ?? "");
    }

    return copywith(
      (hiragana ?? "") + (other.hiragana ?? ""),
      (katakana ?? "") + (other.katakana ?? ""),
      eng,
    );
  }

  @override
  int get hashCode => ord.hashCode;
}

class KanjiModel extends SoundsBase {
  final String word;
  final List<String> letters;
  final List<String> sounds;
  final List<String> meanings;
  final int visits;
  final double freq;

  final String? fakeMean;

  static const String _separator = "|0|0|";

  KanjiModel(Map<String, Object?> map, {this.fakeMean})
    : word = map["visitedword"] as String,
      letters = (map["letters"] as String).split(" "),
      sounds = (map["sounds"] as String).split(" "),
      meanings = (map["mean"] as String).split(_separator),
      visits = map["visits"] as int,
      freq = map["freq"] as double;

  @override
  Map<String, String> toMap() => {
    "word": word,
    "letters": letters.toString(),
    "sounds": sounds.toString(),
    "mean": meanings.toString(),
    "visits": visits.toString(),
    "frequency": freq.toString(),
  };
}
