import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';

enum LightningEffectType { thin, glow, striking }

extension GetBorder on LightningEffectType {
  ShapeBorder into() => switch (this) {
    LightningEffectType.thin => RoundedRectangleBorder(
      side: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(30)),
      borderRadius: BorderRadiusGeometry.circular(12),
    ),
    LightningEffectType.glow => RoundedRectangleBorder(
      side: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(90)),
      borderRadius: BorderRadiusGeometry.circular(12),
    ),
    LightningEffectType.striking => throw UnimplementedError(),
  };
}
