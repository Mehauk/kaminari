import 'package:flutter/material.dart';

enum TextType {
  labelSmall,
  labelMedium,
  bodyMedium,
  bodyLarge,
  headlineMedium,
  headlineLarge,
  displayLarge,
}

extension on TextType {
  TextStyle? style(BuildContext context) => switch (this) {
    TextType.labelSmall => TextTheme.of(context).labelLarge,
    TextType.labelMedium => TextTheme.of(context).labelMedium,
    TextType.bodyMedium => TextTheme.of(context).bodyMedium,
    TextType.bodyLarge => TextTheme.of(context).bodyLarge,
    TextType.headlineMedium => TextTheme.of(context).headlineMedium,
    TextType.headlineLarge => TextTheme.of(context).headlineLarge,
    TextType.displayLarge => TextTheme.of(context).displayLarge,
  };
}

class CustomText extends StatelessWidget {
  const CustomText(
    this.text,
    this.type, {
    super.key,
    this.fontSizeOverride,
    this.colorOverride,
  });

  final String text;
  final TextType type;
  final double? fontSizeOverride;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: type
          .style(context)
          ?.copyWith(fontSize: fontSizeOverride, color: colorOverride),
    );
  }
}
