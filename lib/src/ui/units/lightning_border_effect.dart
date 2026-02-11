import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';

enum LightningBorderEffectType { thin, glowing, striking }

extension GetBorder on LightningBorderEffectType {
  BoxBorder border() => switch (this) {
    LightningBorderEffectType.thin => BoxBorder.all(
      color: KaminariTheme.surfaceTint.withAlpha(30),
    ),
    LightningBorderEffectType.glowing => BoxBorder.all(
      color: KaminariTheme.surfaceTint.withAlpha(90),
    ),
    LightningBorderEffectType.striking => BoxBorder.fromLTRB(
      left: BorderSide(color: KaminariTheme.surfaceTint, width: 4),
      top: BorderSide(color: KaminariTheme.surfaceTint, width: 1),
      right: BorderSide(color: KaminariTheme.surfaceTint, width: 0.5),
      bottom: BorderSide(color: KaminariTheme.surfaceTint, width: 1),
    ),
  };
}
