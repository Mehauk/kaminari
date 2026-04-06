import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/inner_shadow.dart';

class BgFilter extends StatelessWidget {
  const BgFilter({
    super.key,
    this.child,
    this.innerShadow,
    this.bgColor,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget? child;
  final List<BoxShadow>? innerShadow;
  final BorderRadius borderRadius;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: InnerShadow(
        shadows: innerShadow,
        borderRadius: borderRadius,
        child: ColoredBox(color: bgColor ?? KaminariTheme.card, child: child),
      ),
    );
  }
}
