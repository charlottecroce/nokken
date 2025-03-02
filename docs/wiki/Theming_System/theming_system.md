# Theming System
Nokken implements a theming system with dark and light mode support.

## Theme Components

### AppTheme
The AppTheme class (lib/src/core/theme/app_theme.dart) provides the base theme definitions:

### AppColors
The AppColors class provides theme-aware color values:

### AppTextStyles
The AppTextStyles class provides theme-aware text styles:

## Theme Management
Theme state is managed through Riverpod:
```dart
// Provider for the theme mode
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// Utility functions for theme management
class ThemeUtils {
  static void toggleTheme(WidgetRef ref) {...}
  static void setTheme(WidgetRef ref, ThemeMode mode) {...}
}
```