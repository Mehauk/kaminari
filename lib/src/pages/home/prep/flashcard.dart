import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class FlashcardWidget extends StatelessWidget {
  const FlashcardWidget({
    super.key,
    required this.item,
    required this.isFlipped,
    required this.onTap,
  });

  final EntryAnalysisModel item;
  final bool isFlipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? math.pi : 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (context, angle, child) {
          final isBack = angle >= math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: SizedBox.expand(
              child: isBack
                  ? FlashcardBack(item: item)
                  : FlashcardFront(word: item.word),
            ),
          );
        },
      ),
    );
  }
}

class FlashcardFront extends StatelessWidget {
  const FlashcardFront({super.key, required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: LightningBorderEffectType.striking,
      child: Center(
        child: CustomText(word, TextType.displayLarge, fontSize: 54),
      ),
    );
  }
}

class FlashcardBack extends StatelessWidget {
  const FlashcardBack({super.key, required this.item});
  final EntryAnalysisModel item;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: LightningCard(
        type: LightningBorderEffectType.glowing,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                item.entry.sounds.join(", "),
                TextType.labelMedium,
                color: KaminariTheme.cyan,
                alignment: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomText(
                item.entry.meanings.join("; "),
                TextType.bodyLarge,
                alignment: TextAlign.center,
                maxLines: 5,
              ),
              const SizedBox(height: 32),
              CustomText(
                "Appears ${item.count} times in this chapter",
                TextType.labelSmall,
                color: KaminariTheme.textSecondary.withAlpha(150),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
