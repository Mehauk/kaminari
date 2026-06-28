// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

part 'dictionary_view.freezed.dart';

class DictionaryView extends StatelessWidget {
  final DictionaryEntry? entry;
  final void Function() clearSelection;
  final DictOrientation orientation;
  const DictionaryView(
    this.entry,
    this.clearSelection, {
    super.key,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(sizeFactor: animation, child: child);
      },
      child: _DictionaryContent(entry, clearSelection, orientation),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  final DictionaryEntry? entry;
  final void Function() clearSelection;
  final DictOrientation orientation;
  const _DictionaryContent(this.entry, this.clearSelection, this.orientation);

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.velocity;
        if (orientation == .bottom && velocity.pixelsPerSecond.dy > 0) {
          clearSelection();
        } else if (velocity.pixelsPerSecond.dy < 0) {
          clearSelection();
        }
      },
      child: Container(
        key: ValueKey(entry!.letters.join()), // Forces animation on word change
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(40)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orientation == .bottom) ...[
              InkWell(
                onTap: clearSelection,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: CustomText("\u25BC", .bodyLarge),
                  ),
                ),
              ),
            ] else
              SizedBox(height: 12),
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
            if (orientation == .top) ...[
              InkWell(
                onTap: clearSelection,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CustomText("\u25B2", .bodyLarge),
                  ),
                ),
              ),
            ] else
              SizedBox(height: 12),
          ],
        ),
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

    Set<String> onReadings = {
      ...entry.onReading,
      ...entry.onReading.map((e) => e.split(".").first),
    };

    onReadings = {
      ...onReadings,
      ...onReadings.expand((e) => getVariants(e) ?? [e]),
    };

    onReadings = onReadings
        .expand(
          (e) => [e, if (e.length > 1) "${e.substring(0, e.length - 1)}っ"],
        )
        .toSet();

    Set<String> kunReadings = {
      ...entry.kunReadings,
      ...entry.kunReadings.map((e) => e.split(".").first),
    };

    kunReadings = {
      ...kunReadings,
      ...kunReadings.expand((e) => getVariants(e) ?? [e]),
    };

    kunReadings = kunReadings
        .expand(
          (e) => [
            e,
            if (e.length > 1 && !e.contains("."))
              "${e.substring(0, e.length - 1)}っ",
          ],
        )
        .toSet();

    print("on: $onReadings");
    print("kun: $kunReadings");

    String matchedOn =
        onReadings
            .where(
              (r) =>
                  reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
            )
            .fold<String?>(
              null,
              (longest, current) =>
                  (longest == null ||
                      current.replaceAll("-", "").length >
                          longest.replaceAll("-", "").length)
                  ? current
                  : longest,
            ) ??
        '';

    String matchedKun =
        kunReadings
            .where(
              (r) =>
                  reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
            )
            .fold<String?>(
              null,
              (longest, current) =>
                  (longest == null ||
                      current.replaceAll("-", "").length >
                          longest.replaceAll("-", "").length)
                  ? current
                  : longest,
            ) ??
        '';

    String matchedInverseOn =
        onReadings
            .where(
              (r) => reading.contains(
                JpTransliterate.katakanaToHiragana(
                  r,
                ).replaceAll('-', '').replaceAll(".", ""),
              ),
            )
            .fold<String?>(
              null,
              (longest, current) =>
                  (longest == null || current.length > longest.length)
                  ? current
                  : longest,
            ) ??
        '';

    String matchedInverseKun =
        kunReadings
            .where(
              (r) => reading.contains(
                JpTransliterate.hiraganaToKatakana(
                  r,
                ).replaceAll('-', '').replaceAll(".", ""),
              ),
            )
            .fold<String?>(
              null,
              (longest, current) =>
                  (longest == null || current.length > longest.length)
                  ? current
                  : longest,
            ) ??
        '';

    // take longest match on -> kun -> onInverse -> kunInverse
    final matches = [
      matchedOn,
      matchedKun,
      matchedInverseOn,
      matchedInverseKun,
    ];
    String longestMatch =
        matches.fold<String?>(
          null,
          (longest, current) =>
              (longest == null || current.length > longest.length)
              ? current
              : longest,
        ) ??
        matchedOn;

    // print(matchedOn);
    // print(matchedKun);

    final String displayReading = longestMatch.isNotEmpty
        ? longestMatch
        : entry.onReading.first;

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
            color: (longestMatch.isNotEmpty)
                ? KaminariTheme.cyan.withAlpha(100)
                : KaminariTheme.surfaceTint.withAlpha(50),
            width: (longestMatch.isNotEmpty) ? 1.5 : 1,
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
              color: (longestMatch.isNotEmpty)
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

// 1. Your original Map (corrected 'ぢ')
const Map<String, List<String>> kanaDiacritics = {
  'か': ['が'],
  'き': ['ぎ'],
  'く': ['ぐ'],
  'け': ['げ'],
  'こ': ['ご'],
  'さ': ['ざ'],
  'し': ['じ'],
  'す': ['ず'],
  'せ': ['ぜ'],
  'そ': ['ぞ'],
  'た': ['だ'],
  'ち': ['ぢ'],
  'つ': ['づ'],
  'て': ['で'],
  'と': ['ど'],
  'は': ['ば', 'ぱ'],
  'ひ': ['び', 'ぴ'],
  'ふ': ['ぶ', 'ぷ'],
  'へ': ['べ', 'ぺ'],
  'ほ': ['ぼ', 'ぽ'],
  'カ': ['ガ'],
  'キ': ['ギ'],
  'ク': ['グ'],
  'ケ': ['ゲ'],
  'コ': ['ゴ'],
  'サ': ['ザ'],
  'シ': ['ジ'],
  'ス': ['ズ'],
  'セ': ['ゼ'],
  'ソ': ['ゾ'],
  'タ': ['ダ'],
  'チ': ['ヂ'],
  'ツ': ['ヅ'],
  'テ': ['デ'],
  'ト': ['ド'],
  'ハ': ['バ', 'パ'],
  'ヒ': ['ビ', 'ピ'],
  'フ': ['ブ', 'プ'],
  'ヘ': ['ベ', 'ペ'],
  'ホ': ['ポ'],
  'ウ': ['ヴ'],
};

// 2. Pre-process into a flat lookup map
// This map will contain: 'は' -> [ば, ぱ], 'ば' -> [は, ぱ], 'ぱ' -> [は, ば]
final Map<String, List<String>> fullVariantLookup = _buildFullLookup();

Map<String, List<String>> _buildFullLookup() {
  final Map<String, List<String>> lookup = {};

  kanaDiacritics.forEach((base, diacritics) {
    List<String> family = [base, ...diacritics];

    for (var char in family) {
      // The variants for this char are all other members of the family
      lookup[char] = family.where((item) => item != char).toList();
    }
  });

  return lookup;
}

Iterable<String>? getVariants(String kana) {
  if (kana.isEmpty) return null;

  // 1. Determine where the character we want to change is
  int targetIndex = kana.startsWith('-') ? 1 : 0;

  // Safety check: if string is just "-"
  if (targetIndex >= kana.length) return null;

  // 2. Split the string into Prefix, Target, and Suffix
  final String prefix = kana.substring(0, targetIndex);
  final String targetChar = kana[targetIndex];
  final String suffix = kana.substring(targetIndex + 1);

  // 3. Look up the variants for that specific character
  final variants = fullVariantLookup[targetChar];
  if (variants == null) return null;

  // 4. Reassemble the full strings
  return variants.map((v) => prefix + v + suffix);
}
