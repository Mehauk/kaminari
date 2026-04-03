import 'package:flutter/material.dart';

enum TextType {
  labelSmall,
  labelMedium,
  bodyMedium,
  bodyLarge,
  headlineMedium,
  headlineLarge,
  titleMedium,
  displayLarge,
}

extension on TextType {
  TextStyle? style(BuildContext context) => switch (this) {
    TextType.labelSmall => TextTheme.of(context).labelSmall,
    TextType.labelMedium => TextTheme.of(context).labelMedium,
    TextType.bodyMedium => TextTheme.of(context).bodyMedium,
    TextType.bodyLarge => TextTheme.of(context).bodyLarge,
    TextType.headlineMedium => TextTheme.of(context).headlineMedium,
    TextType.headlineLarge => TextTheme.of(context).headlineLarge,
    TextType.titleMedium => TextTheme.of(context).titleMedium,
    TextType.displayLarge => TextTheme.of(context).displayLarge,
  };
}

class CustomText extends StatelessWidget {
  const CustomText(
    this.text,
    this.type, {
    super.key,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.maxLines = 2,
    this.alignment,
  });

  final String text;
  final TextType type;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextAlign? alignment;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: type
          .style(context)
          ?.copyWith(fontSize: fontSize, color: color, fontWeight: fontWeight),
      maxLines: maxLines,
      textAlign: alignment,
    );
  }
}
