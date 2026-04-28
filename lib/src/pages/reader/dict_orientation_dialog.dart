import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

class DictOrientationDialog extends StatelessWidget {
  const DictOrientationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (prev, curr) => prev.dictOrientation != curr.dictOrientation,
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
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
                    spacing: 12,
                    children: DictOrientation.values.map((orient) {
                      return Expanded(
                        child: _OrientationCard(
                          orientation: orient,
                          isSelected: state.dictOrientation == orient,
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

class _OrientationCard extends StatelessWidget {
  const _OrientationCard({required this.orientation, required this.isSelected});

  final DictOrientation orientation;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ReaderCubit>().setDictOrientation(orientation);
        Navigator.of(context).pop();
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: _PhonePreviewSilhouette(orientation: orientation),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  const Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: KaminariTheme.cyan,
                  ),
                if (isSelected) const SizedBox(width: 4),
                CustomText(
                  orientation.name.capitalize,
                  .labelMedium,
                  color: isSelected
                      ? KaminariTheme.cyan
                      : KaminariTheme.textSecondary,
                  fontSize: 11,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhonePreviewSilhouette extends StatelessWidget {
  final DictOrientation orientation;
  const _PhonePreviewSilhouette({required this.orientation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: KaminariTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KaminariTheme.surfaceTint.withAlpha(50)),
      ),
      clipBehavior: Clip.hardEdge,
      child: switch (orientation) {
        DictOrientation.top => Column(
          children: [
            const _DictBlock(),
            const Expanded(child: _TextLines()),
          ],
        ),
        DictOrientation.bottom => Column(
          children: [
            const Expanded(child: _TextLines()),
            const _DictBlock(),
          ],
        ),
        DictOrientation.dynamic => Stack(
          alignment: Alignment.center,
          children: [
            const _TextLines(),
            const Align(
              alignment: Alignment.topCenter,
              child: _DictBlock(opacity: 0.3),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: _DictBlock(opacity: 0.3),
            ),
            Icon(
              Icons.auto_awesome_outlined,
              color: KaminariTheme.cyan.withAlpha(200),
              size: 20,
            ),
          ],
        ),
      },
    );
  }
}

class _TextLines extends StatelessWidget {
  const _TextLines();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) => _Line(isShort: i == 3)),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final bool isShort;
  const _Line({required this.isShort});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: KaminariTheme.surfaceTint.withAlpha(40),
        borderRadius: BorderRadius.circular(2),
      ),
      width: isShort ? 30 : double.infinity,
    );
  }
}

class _DictBlock extends StatelessWidget {
  final double opacity;
  const _DictBlock({this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: double.infinity,
        height: 32,
        decoration: BoxDecoration(
          color: KaminariTheme.bronze.withAlpha(180),
          border: Border.symmetric(
            horizontal: BorderSide(
              color: KaminariTheme.surfaceTint.withAlpha(40),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Pill(width: 20, alpha: 100),
            const SizedBox(width: 4),
            _Pill(width: 30, alpha: 60),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final double width;
  final int alpha;
  const _Pill({required this.width, required this.alpha});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: KaminariTheme.goldSoft.withAlpha(alpha),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
