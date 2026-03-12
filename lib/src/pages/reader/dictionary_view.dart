// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

part 'dictionary_view.freezed.dart';

class ReaderDictionaryExtension extends StatelessWidget {
  const ReaderDictionaryExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(sizeFactor: animation, child: child);
      },
      child: _DictionaryContent(),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  const _DictionaryContent();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    if (cubit.state.selectedEntry == null) {
      return const SizedBox.shrink();
    }

    final entry = cubit.state.selectedEntry!;

    return Container(
      key: ValueKey(entry.letters.join()), // Forces animation on word change
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                          entry.letters.join(),
                          TextType.headlineLarge,
                          color: KaminariTheme.textTitle,
                        ),
                        const SizedBox(width: 12),
                        CustomText(
                          entry.sounds.join(),
                          TextType.labelMedium,
                          color: KaminariTheme.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      entry.meanings.join("; "),
                      TextType.bodyMedium,
                      maxLines: 3,
                      color: KaminariTheme.textPrimary,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => cubit.clearSelection(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          if (entry.kanjis.isNotEmpty) ...[
            const SizedBox(height: 16),
            _KanjiRow(kanjis: entry.kanjis, wordReadings: entry.sounds),
          ],
        ],
      ),
    );
  }
}

class _KanjiRow extends StatelessWidget {
  const _KanjiRow({required this.kanjis, required this.wordReadings});

  final List<KanjiEntry> kanjis;
  final List<String> wordReadings; // Pass the full word readings for matching

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85, // Increased height to accommodate reading text
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kanjis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            _KanjiCard(entry: kanjis[index], wordReadings: wordReadings),
      ),
    );
  }
}

class _KanjiCard extends StatelessWidget {
  const _KanjiCard({required this.entry, required this.wordReadings});

  final KanjiEntry entry;
  final List<String> wordReadings;

  @override
  Widget build(BuildContext context) {
    // Find if any of the kanji's readings are present in the word's reading
    final String fullWordReading = wordReadings.join("");

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

    Set<String> kunReadings = {
      ...entry.kunReadings,
      ...entry.kunReadings.map((e) => e.split(".").first),
    };

    kunReadings = {
      ...kunReadings,
      ...kunReadings.expand((e) => getVariants(e) ?? [e]),
    };

    // Check On-readings (usually Katakana)
    final String matchedOn = onReadings.firstWhere(
      (r) =>
          fullWordReading.contains(r.replaceAll('-', '').replaceAll(".", "")) ||
          fullWordReading.contains(
            JpTransliterate.katakanaToHiragana(
              r,
            ).replaceAll('-', '').replaceAll(".", ""),
          ),
      orElse: () => '',
    );

    // Check Kun-readings (usually Hiragana)
    final String matchedKun = kunReadings.firstWhere(
      (r) =>
          fullWordReading.contains(r.replaceAll('-', '').replaceAll(".", "")) ||
          fullWordReading.contains(
            JpTransliterate.hiraganaToKatakana(
              r,
            ).replaceAll('-', '').replaceAll(".", ""),
          ),
      orElse: () => '',
    );

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
