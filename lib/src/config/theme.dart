import 'package:flutter/material.dart';

class KaminariTheme {
  const KaminariTheme._();

  static const double borderRadius = 16.0;
  static const double altBorderRadius = 8.0;

  static const Color background = Color(0xFF15130B);
  static const Color surface = Color(0xFF222017);
  static const Color surfaceVariant = Color(0xFF37352B);
  static const Color surfaceContainerLow = Color(0xFF1E1C13);
  static const Color gold = Color(0xFFAA9601);
  static const Color goldSoft = Color(0xFFD5C789);
  static const Color bronze = Color(0xFF524918);
  static const Color cyan = Color(0xFF5CFCFD);
  static const Color textPrimary = Color(0xFFE8E2D4);
  static const Color textSecondary = Color(0xFFCDC6AF);
  static const Color textTitle = Color(0xFFFBE359);
  static const Color surfaceTint = Color(0xFFDDC73F);
  static const Color card = Color(0x991E1E1E);
  static const Color error = Colors.red;

  static final ColorScheme colorScheme = ColorScheme.dark(
    surface: surface,
    surfaceContainerHighest: surfaceVariant,
    primary: Colors.white,
    onPrimary: const Color(0xFF383000),
    primaryContainer: const Color(0xFFFBE359),
    onPrimaryContainer: const Color(0xFF322400),
    secondary: goldSoft,
    onSecondary: const Color(0xFF383002),
    secondaryContainer: bronze,
    onSecondaryContainer: const Color(0xFFC6B97C),
    tertiary: Colors.white,
    onTertiary: const Color(0xFF003737),
    tertiaryContainer: cyan,
    onTertiaryContainer: const Color(0xFF007071),
    onSurface: textPrimary,
    outline: const Color(0xFF96917B),
    outlineVariant: const Color(0xFF4B4735),
    surfaceTint: surfaceTint,
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
  );

  static final TextTheme textTheme = Typography.material2021().white.copyWith(
    displayLarge: const TextStyle(
      fontFamily: 'Space Grotesk',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02,
      color: textPrimary,
    ),
    titleMedium: const TextStyle(
      fontFamily: 'Noto Sans JP',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    headlineLarge: const TextStyle(
      fontFamily: 'Space Grotesk',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'Space Grotesk',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: const TextStyle(
      fontFamily: 'Noto Sans JP',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textSecondary,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    labelMedium: const TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: textSecondary,
    ),
    labelSmall: const TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05,
      color: textSecondary,
    ),
  );

  static final ThemeData theme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      surfaceTintColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Space Grotesk',
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: textTheme,
    iconTheme: IconThemeData(color: colorScheme.onSurface, size: 25),
    primaryIconTheme: IconThemeData(color: colorScheme.onSurface, size: 25),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
        overlayColor: WidgetStatePropertyAll(
          colorScheme.primaryContainer.withAlpha(50),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(
              Radius.circular(borderRadius),
            ),
          ),
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primaryContainer,
      linearTrackColor: bronze.withAlpha(70),
      circularTrackColor: bronze.withAlpha(70),
      refreshBackgroundColor: surfaceVariant,
    ),
    splashColor: colorScheme.tertiaryContainer.withAlpha(50),
    highlightColor: colorScheme.tertiaryContainer.withAlpha(30),
    cardTheme: const CardThemeData(
      color: Color(0x2E222017),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(Colors.black),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.primaryContainer.withAlpha(60);
          }
          return null;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02,
          ),
        ),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: WidgetStatePropertyAll(
          colorScheme.primaryContainer.withAlpha(75),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(textPrimary),
        overlayColor: WidgetStatePropertyAll(colorScheme.primary.withAlpha(30)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(textPrimary),
        side: WidgetStatePropertyAll(
          BorderSide(color: bronze.withAlpha(125), width: 1),
        ),
        overlayColor: WidgetStatePropertyAll(gold.withAlpha(30)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          .symmetric(vertical: 12, horizontal: 24),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return textPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(
          colorScheme.primaryContainer.withAlpha(50),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outline.withAlpha(120), width: 1),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(altBorderRadius)),
          ),
        ),
        textStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            );
          }
          return const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          );
        }),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primaryContainer;
        }
        return textPrimary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primaryContainer.withAlpha(140);
        }
        return textSecondary.withAlpha(120);
      }),
      overlayColor: WidgetStatePropertyAll(
        colorScheme.primaryContainer.withAlpha(50),
      ),
      splashRadius: 22,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.primaryContainer,
      disabledColor: surfaceVariant.withAlpha(180),
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelMedium!.copyWith(color: Colors.black),
      secondaryLabelStyle: textTheme.labelMedium!.copyWith(
        color: Colors.black87,
      ),
      brightness: Brightness.dark,
      elevation: 0,
      pressElevation: 0,
      side: BorderSide(
        color: colorScheme.primaryContainer.withAlpha(140),
        width: 1,
      ),
      checkmarkColor: Colors.black87,
    ),
    inputDecorationTheme: InputDecorationTheme(
      errorStyle: textTheme.bodyLarge?.copyWith(
        color: error,
        fontWeight: .w300,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w300),
      helperStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w300),
      labelStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w300),
      floatingLabelStyle: textTheme.bodyLarge?.copyWith(
        fontSize: 12,
        fontWeight: .w300,
      ),
      prefixStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w300),
      prefixIconColor: textSecondary,
      suffixStyle: textTheme.bodyLarge?.copyWith(fontWeight: .w300),
      suffixIconColor: textSecondary,
      filled: true,
      fillColor: surfaceContainerLow,
      focusColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(altBorderRadius),
          topRight: Radius.circular(altBorderRadius),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline.withAlpha(70),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(altBorderRadius),
          topRight: Radius.circular(altBorderRadius),
        ),
        borderSide: BorderSide(
          color: colorScheme.outline.withAlpha(70),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(altBorderRadius),
          topRight: Radius.circular(altBorderRadius),
        ),
        borderSide: BorderSide(color: colorScheme.outline, width: 2),
      ),
    ),
  );
}
