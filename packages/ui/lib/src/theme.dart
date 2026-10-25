import 'package:flutter/material.dart';

import 'status_colors.dart';

abstract final class SapaTheme {
  static ThemeData light() => _build(SapaColorSchemes.light, OrderStatusColors.light);

  static ThemeData dark() => _build(SapaColorSchemes.dark, OrderStatusColors.dark);

  static ThemeData _build(ColorScheme scheme, OrderStatusColors statusColors) {
    final textTheme = SapaTypography.textTheme(scheme);
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
    return ThemeData(
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: SapaTypography.family,
      package: SapaTypography.package,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 52), shape: rounded, textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: rounded, textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
        extendedTextStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        helperMaxLines: 2,
        errorMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      extensions: [statusColors],
    );
  }
}

abstract final class SapaColorSchemes {
  static const seed = Color(0xFF2A7F74);

  // Teal from the seed, with a warm orange accent for the main action and the pets.
  static final light = ColorScheme.fromSeed(
    seedColor: seed,
    tertiary: const Color(0xFFB8621B),
    tertiaryContainer: const Color(0xFFFFDCC2),
    onTertiaryContainer: const Color(0xFF4A2800),
  );

  static final dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    tertiary: const Color(0xFFF4A261),
    tertiaryContainer: const Color(0xFF6B3A10),
    onTertiaryContainer: const Color(0xFFFFDCC2),
  );
}

abstract final class SapaTypography {
  static const family = 'Rubik';

  /// The font ships with this package, so every app that uses the theme gets it without declaring it again.
  static const package = 'ui';

  static TextTheme textTheme(ColorScheme scheme) {
    const headline = TextStyle(fontFamily: family, package: package, fontWeight: FontWeight.w500, height: 1.15);
    const body = TextStyle(fontFamily: family, package: package, fontWeight: FontWeight.w400, height: 1.4);
    const label = TextStyle(fontFamily: family, package: package, fontWeight: FontWeight.w500, height: 1.2);
    return TextTheme(
      displayLarge: headline.copyWith(fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -1),
      displayMedium: headline.copyWith(fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: headline.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
      headlineLarge: headline.copyWith(fontSize: 30),
      headlineMedium: headline.copyWith(fontSize: 26),
      headlineSmall: headline.copyWith(fontSize: 22),
      titleLarge: label.copyWith(fontSize: 20),
      titleMedium: label.copyWith(fontSize: 16),
      titleSmall: label.copyWith(fontSize: 14),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body.copyWith(fontSize: 14),
      bodySmall: body.copyWith(fontSize: 12),
      labelLarge: label.copyWith(fontSize: 14, letterSpacing: 0.1),
      labelMedium: label.copyWith(fontSize: 12, letterSpacing: 0.3),
      labelSmall: label.copyWith(fontSize: 11, letterSpacing: 0.4),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
