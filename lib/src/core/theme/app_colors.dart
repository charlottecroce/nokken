import 'package:flutter/material.dart';
import 'package:nokken/src/core/theme/app_theme.dart';

/// Theme-aware color provider that adjusts based on current theme mode
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Current theme mode
  static ThemeMode themeMode = ThemeMode.dark;

  // Dark and light color schemes
  static final ColorScheme _darkScheme = AppTheme.darkColorScheme;
  static final ColorScheme _lightScheme = AppTheme.lightColorScheme;

  /// Get current scheme based on theme mode
  static ColorScheme get current =>
      themeMode == ThemeMode.light ? _lightScheme : _darkScheme;

  /// Method to change theme mode
  static void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    // A notifier could be added here for more reactive theme changes
  }

  // Basic theme colors
  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get secondary => current.secondary;
  static Color get onSecondary => current.onSecondary;
  static Color get tertiary => current.tertiary;
  static Color get onTertiary => current.onTertiary;

  // Surface colors
  static Color get surface => current.surface;
  static Color get surfaceContainer => current.surfaceContainer;
  static Color get onSurface => current.onSurface;
  static Color get onSurfaceVariant => current.onSurfaceVariant;

  // Status colors
  static Color get error => current.error;
  static Color get errorContainer => current.errorContainer;
  static Color get success =>
      themeMode == ThemeMode.light ? AppTheme.greenLight : AppTheme.greenDark;
  static Color get warning =>
      themeMode == ThemeMode.light ? AppTheme.orangeLight : AppTheme.orangeDark;
  static Color get info => current.primary;

  // Medication type colors
  static Color get oralMedication => themeMode == ThemeMode.light
      ? AppTheme.oralMedColorLight
      : AppTheme.oralMedColorDark;

  static Color get topical => themeMode == ThemeMode.light
      ? AppTheme.topicalColorLight
      : AppTheme.topicalColorDark;

  static Color get patch => themeMode == ThemeMode.light
      ? AppTheme.patchColorLight
      : AppTheme.patchColorDark;

  static Color get injection => themeMode == ThemeMode.light
      ? AppTheme.injectionColorLight
      : AppTheme.injectionColorDark;

  // Appointment type colors
  static Color get bloodwork => themeMode == ThemeMode.light
      ? AppTheme.bloodworkColorLight
      : AppTheme.bloodworkColorDark;

  static Color get doctorAppointment => themeMode == ThemeMode.light
      ? AppTheme.doctorApptColorLight
      : AppTheme.doctorApptColorDark;

  static Color get surgery => themeMode == ThemeMode.light
      ? AppTheme.surgeryColorLight
      : AppTheme.surgeryColorDark;

  // Other UI element colors
  static Color get shadow => current.shadow;
  static Color get outline => current.outline;
  static Color get cardColor => current.surfaceContainer;
}
