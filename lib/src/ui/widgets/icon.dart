import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';

enum LightningIconType { basic, golden, glowing }

extension on LightningIconType {
  Color? get color => switch (this) {
    LightningIconType.basic => null,
    LightningIconType.golden => KaminariTheme.textTitle,
    LightningIconType.glowing => KaminariTheme.textTitle,
  };

  List<BoxShadow>? get shadows => switch (this) {
    LightningIconType.basic => null,
    LightningIconType.golden => null,
    LightningIconType.glowing => [
      BoxShadow(
        color: KaminariTheme.cyan,
        blurRadius: 8,
        offset: const Offset(1, 1),
      ),
    ],
  };
}

class LightningIcon extends StatelessWidget {
  const LightningIcon(
    this.icon, {
    super.key,
    this.type = LightningIconType.basic,
  });

  final IconData icon;
  final LightningIconType type;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: type.color, size: 32, shadows: type.shadows);
  }
}

class LightningIconButton extends StatelessWidget {
  const LightningIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: .circular(KaminariTheme.borderRadius),
        child: BgFilter(
          bgColor: KaminariTheme.colorScheme.primaryContainer.withAlpha(30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: .circular(KaminariTheme.borderRadius),
              border: LightningBorderEffectType.thin.border(),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(icon, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
