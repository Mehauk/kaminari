import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class DictOrientationDialog extends StatelessWidget {
  const DictOrientationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (prev, curr) => prev.dictOrientation != curr.dictOrientation,
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: LightningCard(
            type: .glowing,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText('Dictionary Position', .headlineMedium),
                  const SizedBox(height: 4),
                  CustomText(
                    'Choose where the dictionary panel appears.',
                    .labelMedium,
                    color: KaminariTheme.textSecondary,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _OrientationCard(
                          orientation: DictOrientation.bottom,
                          isSelected:
                              state.dictOrientation == DictOrientation.bottom,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _OrientationCard(
                          orientation: DictOrientation.top,
                          isSelected:
                              state.dictOrientation == DictOrientation.top,
                        ),
                      ),
                    ],
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

class _OrientationCard extends StatelessWidget {
  const _OrientationCard({
    required this.orientation,
    required this.isSelected,
  });

  final DictOrientation orientation;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool isBottom = orientation == DictOrientation.bottom;
    final label = isBottom ? 'Bottom' : 'Top';

    return GestureDetector(
      onTap: () {
        context.read<ReaderCubit>().setDictOrientation(orientation);
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: KaminariTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(KaminariTheme.borderRadius),
          border: Border.all(
            color: isSelected
                ? KaminariTheme.cyan
                : KaminariTheme.surfaceTint.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Phone silhouette ─────────────────────────────────
            Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: KaminariTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: KaminariTheme.surfaceTint.withAlpha(50),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: isBottom
                    ? [
                        // Text lines fill the top
                        Expanded(child: _TextLines()),
                        // Dict panel anchored at bottom
                        _DictBlock(),
                      ]
                    : [
                        // Dict panel at top
                        _DictBlock(),
                        // Text lines fill the bottom
                        Expanded(child: _TextLines()),
                      ],
              ),
            ),
            const SizedBox(height: 10),
            // ── Label + check row ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: KaminariTheme.cyan,
                  ),
                  const SizedBox(width: 4),
                ],
                CustomText(
                  label,
                  .labelMedium,
                  color: isSelected
                      ? KaminariTheme.cyan
                      : KaminariTheme.textSecondary,
                  fontSize: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal lines that simulate text.
class _TextLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isShort = i == 4; // last line is shorter
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: isShort ? 0.55 : 1.0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: KaminariTheme.surfaceTint.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The coloured block representing the dictionary panel.
class _DictBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: KaminariTheme.bronze.withAlpha(180),
        border: Border(
          top: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(40)),
          bottom: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(40)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: KaminariTheme.goldSoft.withAlpha(100),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 44,
            height: 6,
            decoration: BoxDecoration(
              color: KaminariTheme.goldSoft.withAlpha(60),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
