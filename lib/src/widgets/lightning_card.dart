import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/widgets/backdrop_filter.dart';
import 'package:kaminari/src/widgets/lightning_effect.dart';

class LightningCard extends StatelessWidget {
  const LightningCard({
    super.key,
    required this.type,
    this.child,
    this.innerShadow, // Optional parameter
  });

  final LightningEffectType type;
  final Widget? child;
  final List<BoxShadow>? innerShadow;

  @override
  Widget build(BuildContext context) {
    // We assume a standard radius here, or you can extract it from 'type'
    final borderRadius = BorderRadius.circular(KaminariTheme.borderRadius);

    return ClipRRect(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent, // Allow BgFilter to show
        shape: type.into(),
        child: BgFilter(
          innerShadow: innerShadow,
          borderRadius: borderRadius,
          child: child,
        ),
      ),
    );
  }
}
