import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const background = Color(0xFFF7F4ED);
  static const surface = Color(0xFFFFFCF6);
  static const primary = Color(0xFF4F8073);
  static const primaryContainer = Color(0xFFDCEAE4);
  static const secondary = Color(0xFFA8BFA7);
  static const secondaryContainer = Color(0xFFE7EEDF);
  static const coral = Color(0xFFE98B72);
  static const coralContainer = Color(0xFFF9DFD7);
  static const charcoal = Color(0xFF202724);
  static const muted = Color(0xFF66706B);

  static const darkBackground = Color(0xFF111815);
  static const darkSurface = Color(0xFF19221E);
  static const darkPrimary = Color(0xFF9BC9BA);
  static const darkPrimaryContainer = Color(0xFF29483E);
  static const darkSecondary = Color(0xFFC1D2BC);
  static const darkCoral = Color(0xFFFFB39B);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.charcoal,
      secondary: AppColors.secondary,
      onSecondary: AppColors.charcoal,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.charcoal,
      tertiary: AppColors.coral,
      onTertiary: Color(0xFF452019),
      tertiaryContainer: AppColors.coralContainer,
      onTertiaryContainer: Color(0xFF452019),
      error: Color(0xFFBA4A3A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD4),
      onErrorContainer: Color(0xFF410006),
      surface: AppColors.surface,
      onSurface: AppColors.charcoal,
      surfaceContainerHighest: Color(0xFFECE9E1),
      onSurfaceVariant: AppColors.muted,
      outline: Color(0xFF7D8782),
      outlineVariant: Color(0xFFCDD2CE),
      shadow: Color(0x22000000),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFF2E3733),
      onInverseSurface: Color(0xFFF0F2EF),
      inversePrimary: Color(0xFF9BC9BA),
      surfaceTint: AppColors.primary,
    );
    return _base(scheme)
        .copyWith(scaffoldBackgroundColor: AppColors.background);
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: Color(0xFF07372B),
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFD0F0E3),
      secondary: AppColors.darkSecondary,
      onSecondary: Color(0xFF233425),
      secondaryContainer: Color(0xFF354A38),
      onSecondaryContainer: Color(0xFFDDE9D8),
      tertiary: AppColors.darkCoral,
      onTertiary: Color(0xFF5A1A0B),
      tertiaryContainer: Color(0xFF7B3020),
      onTertiaryContainer: Color(0xFFFFDAD0),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFE3E9E5),
      surfaceContainerHighest: Color(0xFF29332E),
      onSurfaceVariant: Color(0xFFBEC9C3),
      outline: Color(0xFF89938D),
      outlineVariant: Color(0xFF3F4944),
      shadow: Color(0x66000000),
      scrim: Color(0x99000000),
      inverseSurface: Color(0xFFE3E9E5),
      onInverseSurface: Color(0xFF29332E),
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.darkPrimary,
    );
    return _base(scheme)
        .copyWith(scaffoldBackgroundColor: AppColors.darkBackground);
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          height: 1.12,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.42),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarIconBrightness:
              scheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.65),
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
