import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

class KanjiAlignmentDialog extends StatelessWidget {
  const KanjiAlignmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: LightningCard(
            type: .striking,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText('Kanji Card Alignment', .headlineMedium),
                  const SizedBox(height: 4),
                  CustomText(
                    'Align the dictionary view to the left or right side of the panel.',
                    .labelMedium,
                    color: KaminariTheme.textSecondary,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 12,
                    children: KanjiAlignment.values.map((alignment) {
                      return Expanded(
                        child: _AlignmentOptionCard(
                          alignment: alignment,
                          isSelected: state.kanjiAlignment == alignment,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlignmentOptionCard extends StatelessWidget {
  const _AlignmentOptionCard({
    required this.alignment,
    required this.isSelected,
  });
  final KanjiAlignment alignment;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ReaderCubit>().setKanjiAlignment(alignment);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: KaminariTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(KaminariTheme.altBorderRadius),
          border: Border.all(
            color: isSelected
                ? KaminariTheme.cyan
                : KaminariTheme.surfaceTint.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            _KanjiPreviewDiagram(alignment: alignment),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CustomText(
                alignment.name.capitalize,
                .labelMedium,
                fontSize: 12,
                color: isSelected ? KaminariTheme.cyan : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiPreviewDiagram extends StatelessWidget {
  const _KanjiPreviewDiagram({required this.alignment});
  final KanjiAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: KaminariTheme.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: alignment == .left ? .start : .end,
        children: [
          // Word/Reading placeholder
          Container(
            height: 8,
            width: 40,
            color: KaminariTheme.textTitle.withAlpha(50),
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            width: 80,
            color: KaminariTheme.textSecondary.withAlpha(30),
          ),
          const Spacer(),
          // Kanji Cards Row
          Row(
            mainAxisAlignment: alignment == KanjiAlignment.left
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: List.generate(
              2,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 18,
                height: 22,
                decoration: BoxDecoration(
                  color: KaminariTheme.bronze.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: KaminariTheme.cyan.withAlpha(50)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
