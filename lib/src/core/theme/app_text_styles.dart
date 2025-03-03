import 'package:flutter/material.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/app_colors.dart';

/// Theme-aware text styles that adjust based on current theme mode
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  /// Get current text theme based on theme mode
  static TextTheme get _current => AppColors.themeMode == ThemeMode.light
      ? _getLightTextTheme()
      : _getDarkTextTheme();

  /// Create the dark theme text styles
  static TextTheme _getDarkTextTheme() => TextTheme(
        displayLarge: AppTheme.displayLarge,
        displayMedium: AppTheme.displayMedium,
        displaySmall: AppTheme.displaySmall,
        headlineLarge: AppTheme.headlineLarge,
        headlineMedium: AppTheme.headlineMedium,
        headlineSmall: AppTheme.headlineSmall,
        titleLarge: AppTheme.titleLarge,
        titleMedium: AppTheme.titleMedium,
        titleSmall: AppTheme.titleSmall,
        bodyLarge: AppTheme.bodyLarge,
        bodyMedium: AppTheme.bodyMedium,
        bodySmall: AppTheme.bodySmall,
        labelLarge: AppTheme.labelLarge,
        labelMedium: AppTheme.labelMedium,
        labelSmall: AppTheme.labelSmall,
      );

  /// Create the light theme text styles with adjusted colors
  static TextTheme _getLightTextTheme() {
    return TextTheme(
      displayLarge: AppTheme.displayLarge.copyWith(color: AppTheme.black),
      displayMedium: AppTheme.displayMedium.copyWith(color: AppTheme.black),
      displaySmall: AppTheme.displaySmall.copyWith(color: AppTheme.black),
      headlineLarge: AppTheme.headlineLarge.copyWith(color: AppTheme.black),
      headlineMedium: AppTheme.headlineMedium.copyWith(color: AppTheme.black),
      headlineSmall: AppTheme.headlineSmall.copyWith(color: AppTheme.black),
      titleLarge: AppTheme.titleLarge.copyWith(color: AppTheme.black),
      titleMedium: AppTheme.titleMedium.copyWith(color: AppTheme.black),
      titleSmall: AppTheme.titleSmall.copyWith(color: AppTheme.black),
      bodyLarge: AppTheme.bodyLarge.copyWith(color: AppTheme.black),
      bodyMedium: AppTheme.bodyMedium.copyWith(color: AppTheme.black),
      bodySmall: AppTheme.bodySmall.copyWith(color: AppTheme.black),
      labelLarge: AppTheme.labelLarge.copyWith(color: AppTheme.black),
      labelMedium: AppTheme.labelMedium.copyWith(color: AppTheme.black),
      labelSmall: AppTheme.labelSmall.copyWith(color: AppTheme.black),
    );
  }

  // Display styles
  static TextStyle get displayLarge => _current.displayLarge!;
  static TextStyle get displayMedium => _current.displayMedium!;
  static TextStyle get displaySmall => _current.displaySmall!;

  // Headline styles
  static TextStyle get headlineLarge => _current.headlineLarge!;
  static TextStyle get headlineMedium => _current.headlineMedium!;
  static TextStyle get headlineSmall => _current.headlineSmall!;

  // Title styles
  static TextStyle get titleLarge => _current.titleLarge!;
  static TextStyle get titleMedium => _current.titleMedium!;
  static TextStyle get titleSmall => _current.titleSmall!;

  // Body styles
  static TextStyle get bodyLarge => _current.bodyLarge!;
  static TextStyle get bodyMedium => _current.bodyMedium!;
  static TextStyle get bodySmall => _current.bodySmall!;

  // Label styles
  static TextStyle get labelLarge => _current.labelLarge!;
  static TextStyle get labelMedium => _current.labelMedium!;
  static TextStyle get labelSmall => _current.labelSmall!;

  // Utility styles - these adjust color based on current theme automatically
  static TextStyle get buttonText => AppColors.themeMode == ThemeMode.light
      ? AppTheme.buttonText.copyWith(color: AppTheme.black)
      : AppTheme.buttonText;

  static TextStyle get caption => AppColors.themeMode == ThemeMode.light
      ? AppTheme.caption.copyWith(color: AppTheme.black.withAlpha(179))
      : AppTheme.caption;

  static TextStyle get overline => AppColors.themeMode == ThemeMode.light
      ? AppTheme.overline.copyWith(color: AppTheme.black)
      : AppTheme.overline;

  static TextStyle get error => AppColors.themeMode == ThemeMode.light
      ? AppTheme.error.copyWith(color: AppTheme.pinkDark.withRed(220))
      : AppTheme.error;

  static TextStyle get link => AppColors.themeMode == ThemeMode.light
      ? AppTheme.link.copyWith(color: AppTheme.blueLight)
      : AppTheme.link;
}
