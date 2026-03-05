import 'package:flutter/material.dart';
import 'package:kaminari/src/ui/units/text.dart';

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

class DictionaryView extends StatelessWidget {
  final DictionaryEntry _entry;
  const DictionaryView(this._entry, {super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle? theme = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 28);
    return Center(
      child: SingleChildScrollView(
        child: Column(children: _createEntry(theme)),
      ),
    );
  }

  List<Widget> _createEntry(TextStyle? theme) {
    bool color = false;
    List<TextSpan> topChildren = [];
    List<TextSpan> botChildren = [];
    for (var i = 0; i < _entry.letters.length; i++) {
      if (_entry.letters[i] != _entry.sounds[i]) {
        color = !color;
        topChildren.add(
          TextSpan(
            text: _entry.letters[i],
            style: theme?.copyWith(
              color: color ? Colors.amber : Colors.redAccent,
            ),
          ),
        );
        botChildren.add(
          TextSpan(
            text: _entry.sounds[i],
            style: theme?.copyWith(
              color: color ? Colors.amber : Colors.redAccent,
            ),
          ),
        );
      } else {
        topChildren.add(TextSpan(text: _entry.letters[i]));
        botChildren.add(TextSpan(text: _entry.sounds[i]));
      }
    }
    topChildren.add(TextSpan(text: "\n"));
    botChildren.add(TextSpan(text: "\n"));

    // populate main spans
    final List<TextSpan> mainSpans = [
      TextSpan(children: topChildren),
      TextSpan(children: botChildren),
      TextSpan(
        text: _entry.meanings.join("; "),
        style: theme?.copyWith(fontSize: 14),
      ),
    ];

    // create word reading
    final RichText mainText = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(style: theme, children: mainSpans),
      textScaler: TextScaler.linear(1.4),
    );

    return [
      mainText,
      const SizedBox(height: 8),
      ..._entry.kanjis.map((e) => KanjiReadingView(e)),
    ];
  }
}

class KanjiReadingView extends StatelessWidget {
  final KanjiEntry ke;
  const KanjiReadingView(this.ke, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(border: Border(top: BorderSide())),
      child: Row(
        children: [
          Expanded(child: Center(child: CustomText(ke.kanji, .headlineMedium))),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _TextDiv("Def", ke.meanings.join(";  ")),
                SizedBox(height: 5),
                _TextDiv("On", ke.onReading.join(",  ")),
                SizedBox(height: 5),
                _TextDiv("Kun", ke.kunReadings.join(",  ")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDiv extends StatelessWidget {
  final String type;
  final String text;
  const _TextDiv(this.type, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide())),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: CustomText(type, .headlineMedium)),
          SizedBox(width: 5),
          Expanded(
            flex: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(), left: BorderSide()),
              ),
              child: CustomText(text, .headlineMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class DictionaryEntry {
  final List<String> letters;
  final List<String> sounds;
  final List<String> meanings;
  final List<KanjiEntry> kanjis;
  final double frequency;

  DictionaryEntry(Map<String, Object?> map, {required this.kanjis})
    : letters = (map["letters"] as String).split(" "),
      sounds = (map["sounds"] as String).split(" "),
      meanings = (map["mean"] as String).split("|0|0|"),
      frequency = map["freq"] as double;

  @override
  String toString() {
    return "Letters: $letters\nSounds: $sounds\nkanjis: \n${kanjis.fold<String>("", (previousValue, element) => "$previousValue$element\n")}";
  }
}

class KanjiEntry {
  final String kanji;
  final List<String> meanings;
  final List<String> onReading;
  final List<String> kunReadings;

  KanjiEntry(Map<String, Object?> map)
    : kanji = map["letter"] as String,
      meanings = (map["mean"] as String).split("|0|0|"),
      onReading = (map["kon"] as String).split("|0|0|"),
      kunReadings = (map["kun"] as String).split("|0|0|");

  @override
  String toString() {
    return "$kanji -- $meanings";
  }
}
