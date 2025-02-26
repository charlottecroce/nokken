//
//  app.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/shared/providers/theme_provider.dart';
import 'package:nokken/src/routes/app_router.dart';
import 'package:nokken/src/screens/main_screen.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class NokkenApp extends ConsumerWidget {
  const NokkenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // When theme changes, update the static AppColors theme mode
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
