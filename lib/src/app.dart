//
//  app.dart
//  Main application configuration
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/core/theme/providers/theme_provider.dart';
import 'package:nokken/src/core/services/navigation/routes/app_router.dart';
import 'package:nokken/src/core/screens/main_screen.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/app_colors.dart';

/// Root widget for the app
/// Handles theme configuration and routing
class NokkenApp extends ConsumerWidget {
  const NokkenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider to rebuild when theme changes
    final themeMode = ref.watch(themeProvider);
    // When theme changes, update the AppColors._themeMode var
    AppColors.setThemeMode(themeMode);

    return MaterialApp(
      title: 'Nokken',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
