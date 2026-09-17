// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/services/english_dictionary_service.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

part 'dictionary_view.freezed.dart';

enum KanjiAlignment { left, right }

enum DictOrientation { top, bottom, dynamic }

class DictionaryView extends StatelessWidget {
  final DictionaryEntry? entry;
  final EnglishDictionaryEntry? englishEntry;
  final bool showDownloadPrompt;
  final bool isDownloading;
  final double downloadProgress;
  final void Function()? onDownload;

  final void Function() clearSelection;
  final DictOrientation orientation;
  final KanjiAlignment alignment;

  const DictionaryView({
    super.key,
    this.entry,
    this.englishEntry,
    this.showDownloadPrompt = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.onDownload,
    required this.clearSelection,
    required this.orientation,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(sizeFactor: animation, child: child);
      },
      child: _DictionaryContent(
        entry: entry,
        englishEntry: englishEntry,
        showDownloadPrompt: showDownloadPrompt,
        isDownloading: isDownloading,
        downloadProgress: downloadProgress,
        onDownload: onDownload,
        clearSelection: clearSelection,
        orientation: orientation,
        alignment: alignment,
      ),
    );
  }
}

class _DictionaryContent extends StatelessWidget {
  final DictionaryEntry? entry;
  final EnglishDictionaryEntry? englishEntry;
  final bool showDownloadPrompt;
  final bool isDownloading;
  final double downloadProgress;
  final void Function()? onDownload;

  final void Function() clearSelection;
  final DictOrientation orientation;
  final KanjiAlignment alignment;

  const _DictionaryContent({
    this.entry,
    this.englishEntry,
    required this.showDownloadPrompt,
    required this.isDownloading,
    required this.downloadProgress,
    this.onDownload,
    required this.clearSelection,
    required this.orientation,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null && englishEntry == null && !showDownloadPrompt) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.velocity;
        if (orientation == DictOrientation.bottom &&
            velocity.pixelsPerSecond.dy > 0) {
          clearSelection();
        } else if (orientation == DictOrientation.top &&
            velocity.pixelsPerSecond.dy < 0) {
          clearSelection();
        }
      },
      child: Container(
        key: ValueKey(
          entry?.letters.join() ??
              englishEntry?.word ??
              showDownloadPrompt.toString(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(40)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment == KanjiAlignment.left
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (orientation == DictOrientation.bottom) ...[
              InkWell(
                onTap: clearSelection,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: CustomText("\u25BC", TextType.bodyLarge),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 12),

            if (showDownloadPrompt) ...[
              _buildDownloadPrompt(),
            ] else if (englishEntry != null) ...[
              _buildEnglishEntry(),
            ] else if (entry != null) ...[
              _buildJapaneseEntry(context),
            ],

            if (orientation == DictOrientation.top) ...[
              InkWell(
                onTap: clearSelection,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CustomText("\u25B2", TextType.bodyLarge),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadPrompt() {
    return Column(
      crossAxisAlignment: alignment == KanjiAlignment.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        CustomText(
          "Offline Dictionary Required",
          TextType.titleMedium,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 8),
        CustomText(
          "To look up English words, you need to download the offline dictionary database.",
          TextType.bodyMedium,
          color: KaminariTheme.textPrimary,
        ),
        const SizedBox(height: 16),
        if (isDownloading) ...[
          LinearProgressIndicator(value: downloadProgress),
          const SizedBox(height: 8),
          CustomText(
            "Downloading... ${(downloadProgress * 100).toStringAsFixed(1)}%",
            TextType.labelSmall,
            color: KaminariTheme.textSecondary,
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            label: const Text("Download Dictionary (~15MB)"),
          ),
        ],
      ],
    );
  }

  Widget _buildEnglishEntry() {
    return Column(
      crossAxisAlignment: alignment == KanjiAlignment.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Wrap(
          children: [
            CustomText(
              englishEntry!.word,
              TextType.headlineLarge,
              color: KaminariTheme.textTitle,
            ),
            if (englishEntry!.pronunciation.isNotEmpty) ...[
              const SizedBox(width: 12),
              CustomText(
                "/${englishEntry!.pronunciation}/",
                TextType.labelMedium,
                color: KaminariTheme.cyan,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        CustomText(
          englishEntry!.definitions.isNotEmpty
              ? englishEntry!.definitions.join("\n\n")
              : "No definition found.",
          TextType.bodyMedium,
          maxLines: 10,
          color: KaminariTheme.textPrimary,
        ),
        if (englishEntry!.etymology.isNotEmpty) ...[
          const SizedBox(height: 12),
          CustomText(
            "Etymology:",
            TextType.labelSmall,
            color: KaminariTheme.textTitle,
          ),
          CustomText(
            englishEntry!.etymology,
            TextType.bodyMedium,
            maxLines: 6,
            color: KaminariTheme.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildJapaneseEntry(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment == KanjiAlignment.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: alignment == KanjiAlignment.left
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
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
                    entry!.meanings.join("; ").trim().isNotEmpty
                        ? entry!.meanings.join("; ")
                        : " --- ",
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
            alignment: alignment,
          ),
        ],
      ],
    );
  }
}

class _KanjiRow extends StatelessWidget {
  const _KanjiRow({
    required this.kanjis,
    required this.wordReadings,
    required this.letters,
    required this.alignment,
  });

  final List<String> letters;
  final List<KanjiEntry> kanjis;
  final List<String> wordReadings;
  final KanjiAlignment alignment;

  @override
  Widget build(BuildContext context) {
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

    final int total = kanjis.length;

    return SizedBox(
      height: 85,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: alignment == KanjiAlignment.right,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                spacing: 10,
                mainAxisAlignment: alignment == KanjiAlignment.left
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  ...kanjis.asMap().entries.map(
                    (e) => _KanjiCard(
                      entry: e.value,
                      wordReadings: readings,
                      index: e.key,
                      total: total,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KanjiCard extends StatelessWidget {
  const _KanjiCard({
    required this.entry,
    required this.wordReadings,
    required this.index,
    required this.total,
  });

  final KanjiEntry entry;
  final List<String> wordReadings;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final String reading;

    if (wordReadings.length > index && wordReadings.length == total) {
      reading = wordReadings[index];
    } else {
      reading = wordReadings.join("");
    }

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

    String? matchedOn = onReadings
        .where(
          (r) => reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
        )
        .longest;

    String? matchedKun = kunReadings
        .where(
          (r) => reading.contains(r.replaceAll('-', '').replaceAll(".", "")),
        )
        .longest;

    String? matchedInverseOn = onReadings
        .where(
          (r) => reading.contains(
            JpTransliterate.katakanaToHiragana(
              r,
            ).replaceAll('-', '').replaceAll(".", ""),
          ),
        )
        .longest;

    String? matchedInverseKun = kunReadings
        .where(
          (r) => reading.contains(
            JpTransliterate.hiraganaToKatakana(
              r,
            ).replaceAll('-', '').replaceAll(".", ""),
          ),
        )
        .longest;

    final matches = [
      matchedOn,
      matchedKun,
      matchedInverseOn,
      matchedInverseKun,
    ];

    String longestMatch = matches.longest ?? '';

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
            CustomText(
              displayReading,
              TextType.labelSmall,
              fontSize: 11,
              color: (longestMatch.isNotEmpty)
                  ? KaminariTheme.cyan
                  : KaminariTheme.textSecondary,
            ),
            const SizedBox(height: 2),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: LightningCard(
          type: .striking,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        TextType.bodyMedium,
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
                        TextType.bodyMedium,
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

  Map<String, dynamic> toJson() => {
    'map': map,
    'kanjis': kanjis.map((e) => e.toJson()).toList(),
  };

  factory DictionaryEntry.fromCacheJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      Map<String, Object?>.from(json['map']),
      kanjis: (json['kanjis'] as List)
          .map((e) => KanjiEntry.fromCacheJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
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

  Map<String, dynamic> toJson() => {'map': map};

  factory KanjiEntry.fromCacheJson(Map<String, dynamic> json) {
    return KanjiEntry(Map<String, Object?>.from(json['map']));
  }
}

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

final Map<String, List<String>> fullVariantLookup = _buildFullLookup();

Map<String, List<String>> _buildFullLookup() {
  final Map<String, List<String>> lookup = {};

  kanaDiacritics.forEach((base, diacritics) {
    List<String> family = [base, ...diacritics];

    for (var char in family) {
      lookup[char] = family.where((item) => item != char).toList();
    }
  });

  return lookup;
}

Iterable<String>? getVariants(String kana) {
  if (kana.isEmpty) return null;

  int targetIndex = kana.startsWith('-') ? 1 : 0;

  if (targetIndex >= kana.length) return null;

  final String prefix = kana.substring(0, targetIndex);
  final String targetChar = kana[targetIndex];
  final String suffix = kana.substring(targetIndex + 1);

  final variants = fullVariantLookup[targetChar];
  if (variants == null) return null;

  return variants.map((v) => prefix + v + suffix);
}

extension on Iterable<String?> {
  String? get longest => fold(
    null,
    (longest, current) =>
        (longest == null ||
            (current ?? '').replaceAll("-", "").length >
                longest.replaceAll("-", "").length)
        ? current
        : longest,
  );
}
