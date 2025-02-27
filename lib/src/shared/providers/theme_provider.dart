//
//  theme_provider.dart
//  Provider and utilities for theme management
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

/// Provider for the application theme mode (light/dark)
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Utility functions for theme management
class ThemeUtils {
  /// Toggle between light and dark mode
  static void toggleTheme(WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    final newTheme =
        currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    // Update the theme provider
    ref.read(themeProvider.notifier).state = newTheme;

    // Update the static AppColors._themMode var
    AppColors.setThemeMode(newTheme);
  }

  /// Set a specific theme
  static void setTheme(WidgetRef ref, ThemeMode mode) {
    // Update the theme provider
    ref.read(themeProvider.notifier).state = mode;

    // Update the static AppColors._themMode var
    AppColors.setThemeMode(mode);
  }
}
