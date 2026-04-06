import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';

class LightningCard extends StatelessWidget {
  const LightningCard({
    super.key,
    required this.type,
    this.child,
    this.innerShadow, // Optional parameter
  });

  final LightningBorderEffectType type;
  final Widget? child;
  final List<BoxShadow>? innerShadow;

  @override
  Widget build(BuildContext context) {
    // We assume a standard radius here, or you can extract it from 'type'
    final borderRadius = BorderRadius.circular(KaminariTheme.borderRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        position: .foreground,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: type.border(),
          borderRadius: borderRadius,
        ),
        child: BgFilter(
          innerShadow: innerShadow,
          borderRadius: borderRadius,
          child: child,
        ),
      ),
    );
  }
}
