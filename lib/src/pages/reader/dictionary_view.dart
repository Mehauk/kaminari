// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

part 'dictionary_view.freezed.dart';

class DictionaryView extends StatelessWidget {
  final DictionaryEntry? entry;
  final void Function() clearSelection;
  const DictionaryView(this.entry, this.clearSelection, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(sizeFactor: animation, child: child);
      },
      child: _DictionaryContent(entry, clearSelection),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  final DictionaryEntry? entry;
  final void Function() clearSelection;
  const _DictionaryContent(this.entry, this.clearSelection);

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const SizedBox.shrink();
    }

    return Container(
      key: ValueKey(entry!.letters.join()), // Forces animation on word change
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(40)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      children: [
                        CustomText(
                          entry!.letters.join(),
                          TextType.headlineLarge,
                          color: KaminariTheme.textTitle,
                        ),
                        const SizedBox(width: 12),
                        CustomText(
                          entry!.sounds.join(),
                          TextType.labelMedium,
                          color: KaminariTheme.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      entry!.meanings.join("; "),
                      TextType.bodyMedium,
                      maxLines: 3,
                      color: KaminariTheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry!.kanjis.isNotEmpty) ...[
            const SizedBox(height: 16),
            _KanjiRow(
              kanjis: entry!.kanjis,
              wordReadings: entry!.sounds,
              letters: entry!.letters,
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: clearSelection,
            child: Center(child: CustomText("\u25B2", .bodyLarge)),
          ),
        ],
      ),
    );
  }
}

class _KanjiRow extends StatelessWidget {
  const _KanjiRow({
    required this.kanjis,
    required this.wordReadings,
    required this.letters,
  });

  final List<String> letters;
  final List<KanjiEntry> kanjis;
  final List<String> wordReadings; // Pass the full word readings for matching

  @override
  Widget build(BuildContext context) {
    print(":letters");
    print(letters);
    print(wordReadings);
    List<String> readings = [];
    if (wordReadings.length != letters.length) {
      readings = wordReadings;
    }

    for (var i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final r = wordReadings[i];

      if (letter != r) {
        readings.add(r);
      }
    }

    return SizedBox(
      height: 85, // Increased height to accommodate reading text
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kanjis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _KanjiCard(
          entry: kanjis[index],
          wordReadings: readings,
          index: index,
        ),
      ),
    );
  }
}

class _KanjiCard extends StatelessWidget {
  const _KanjiCard({
    required this.entry,
    required this.wordReadings,
    required this.index,
  });

  final KanjiEntry entry;
  final List<String> wordReadings;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Find if any of the kanji's readings are present in the word's reading
    // final String fullWordReading = wordReadings.join("");

    final String reading;

    if (wordReadings.length > index) {
      reading = wordReadings[index];
    } else {
      reading = wordReadings.join("");
    }

    print(wordReadings);
    print(entry.kanji);
    print(reading);
    print(entry.onReading);
    print(entry.kunReadings);

    Set<String> onReadings = {
      ...entry.onReading,
      ...entry.onReading.map((e) => e.split(".").first),
    };

    onReadings = {
      ...onReadings,
      ...onReadings.expand((e) => getVariants(e) ?? [e]),
    };

    onReadings = {
      ...onReadings,
      ...onReadings
          .where((s) => s.length > 1)
          .map((e) => "${e.substring(0, e.length - 1)}っ"),
    };

    Set<String> kunReadings = {
      ...entry.kunReadings,
      ...entry.kunReadings.map((e) => e.split(".").first),
    };

    kunReadings = {
      ...kunReadings,
      ...kunReadings.expand((e) => getVariants(e) ?? [e]),
    };

    kunReadings = {
      ...kunReadings,
      ...kunReadings
          .where((s) => s.length > 1)
          .map((e) => "${e.substring(0, e.length - 1)}っ"),
    };

    // Check On-readings (usually Katakana)
    String matchedOn = onReadings.firstWhere(
      (r) => reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
      orElse: () => '',
    );

    // Check Kun-readings (usually Hiragana)
    String matchedKun = kunReadings.firstWhere(
      (r) => reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
      orElse: () => '',
    );

    if (matchedOn == '' && matchedKun == '') {
      matchedOn = onReadings.firstWhere(
        (r) => reading.contains(
          JpTransliterate.katakanaToHiragana(
            r,
          ).replaceAll('-', '').replaceAll(".", ""),
        ),
        orElse: () => '',
      );

      matchedKun = kunReadings.firstWhere(
        (r) => reading.contains(
          JpTransliterate.hiraganaToKatakana(
            r,
          ).replaceAll('-', '').replaceAll(".", ""),
        ),
        orElse: () => '',
      );
    }

    // print(matchedOn);
    // print(matchedKun);

    final String displayReading = matchedOn.isNotEmpty
        ? matchedOn
        : (matchedKun.isNotEmpty ? matchedKun : entry.onReading.first);

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => _KanjiDetailDialog(entry: entry),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (matchedOn.isNotEmpty || matchedKun.isNotEmpty)
                ? KaminariTheme.cyan.withAlpha(100)
                : KaminariTheme.surfaceTint.withAlpha(50),
            width: (matchedOn.isNotEmpty || matchedKun.isNotEmpty) ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              entry.kanji,
              TextType.labelMedium,
              fontSize: 18,
              color: KaminariTheme.textTitle,
            ),
            const SizedBox(height: 2),
            // The matched Reading
            CustomText(
              displayReading,
              TextType.labelSmall,
              fontSize: 11,
              color: (matchedOn.isNotEmpty || matchedKun.isNotEmpty)
                  ? KaminariTheme.cyan
                  : KaminariTheme.textSecondary,
            ),
            const SizedBox(height: 2),
            // The Meaning
            CustomText(
              entry.meanings.isNotEmpty ? entry.meanings.first : '',
              TextType.labelSmall,
              fontSize: 10,
              color: KaminariTheme.textSecondary.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiDetailDialog extends StatelessWidget {
  const _KanjiDetailDialog({required this.entry});

  final KanjiEntry entry;

  @override
  Widget build(BuildContext context) {
    // Wrap in Dialog to get standard constraints and centering
    return Dialog(
      backgroundColor:
          Colors.transparent, // Let LightningCard handle the background
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
        ), // Prevent it from getting too wide on tablets
        child: LightningCard(
          type: .striking,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Vital: Tells the column to only take required height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      entry.kanji,
                      TextType.displayLarge,
                      color: KaminariTheme.textTitle,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomText(
                  "Meanings",
                  TextType.labelSmall,
                  color: KaminariTheme.cyan,
                ),
                const SizedBox(height: 8),
                CustomText(entry.meanings.join(", "), TextType.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CustomText("On:", TextType.bodyMedium),

                    Expanded(
                      child: CustomText(
                        " ${entry.onReading.join(" , ")}",
                        .bodyMedium,
                        color: KaminariTheme.cyan,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CustomText("kun:", TextType.bodyMedium),

                    Expanded(
                      child: CustomText(
                        " ${entry.kunReadings.join(" , ")}",
                        .bodyMedium,
                        color: KaminariTheme.cyan,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@freezed
class DictionaryEntry with _$DictionaryEntry {
  final Map<String, Object?> map;
  final List<String> letters;
  final List<String> sounds;
  final List<String> meanings;
  final List<KanjiEntry> kanjis;
  final double frequency;

  DictionaryEntry(this.map, {required this.kanjis})
    : letters = (map["letters"] as String).split(" "),
      sounds = (map["sounds"] as String).split(" "),
      meanings = (map["mean"] as String).split("|0|0|"),
      frequency = map["freq"] as double;

  @override
  String toString() {
    return "Letters: $letters\nSounds: $sounds\nkanjis: \n${kanjis.fold<String>("", (previousValue, element) => "$previousValue$element\n")}";
  }
}

@freezed
class KanjiEntry with _$KanjiEntry {
  final Map<String, Object?> map;
  final String kanji;
  final List<String> meanings;
  final List<String> onReading;
  final List<String> kunReadings;

  KanjiEntry(this.map)
    : kanji = map["letter"] as String,
      meanings = (map["mean"] as String).split("|0|0|"),
      onReading = (map["kon"] as String).split("|0|0|"),
      kunReadings = (map["kun"] as String).split("|0|0|");

  @override
  String toString() {
    return "$kanji -- $meanings";
  }
}

// Map of base kana to their diacritic variants
const Map<String, List<String>> kanaDiacritics = {
  // --- HIRAGANA ---
  // K-row -> G-row
  'か': ['が'], 'き': ['ぎ'], 'く': ['ぐ'], 'け': ['げ'], 'こ': ['ご'],
  // S-row -> Z-row
  'さ': ['ざ'], 'し': ['じ'], 'す': ['ず'], 'せ': ['ぜ'], 'そ': ['ぞ'],
  // T-row -> D-row
  'た': ['だ'], 'ち': ['ヂ'], 'つ': ['づ'], 'て': ['で'], 'と': ['ど'],
  // H-row -> B-row & P-row
  'は': ['ば', 'ぱ'],
  'ひ': ['び', 'ぴ'],
  'ふ': ['ぶ', 'ぷ'],
  'へ': ['べ', 'ぺ'],
  'ほ': ['ぼ', 'ぽ'],

  // --- KATAKANA ---
  // K-row -> G-row
  'カ': ['ガ'], 'キ': ['ギ'], 'ク': ['グ'], 'ケ': ['ゲ'], 'コ': ['ゴ'],
  // S-row -> Z-row
  'サ': ['ザ'], 'シ': ['ジ'], 'ス': ['ズ'], 'セ': ['ゼ'], 'ソ': ['ゾ'],
  // T-row -> D-row
  'タ': ['ダ'], 'チ': ['ヂ'], 'ツ': ['ヅ'], 'テ': ['デ'], 'ト': ['ド'],
  // H-row -> B-row & P-row
  'ハ': ['バ', 'パ'],
  'ヒ': ['ビ', 'ピ'],
  'フ': ['ブ', 'プ'],
  'ヘ': ['ベ', 'ペ'],
  'ホ': ['ボ', 'ポ'],
  // V-row
  'ウ': ['ヴ'],
};

// Example function to get variants
Iterable<String>? getVariants(String kana) {
  if (kana.isEmpty) return null;
  final vars = kanaDiacritics[kana[0]];
  if (kana.length == 1) return vars;
  return vars?.map((e) => e + kana.substring(1));
}
