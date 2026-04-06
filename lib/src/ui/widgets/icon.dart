import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';

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
