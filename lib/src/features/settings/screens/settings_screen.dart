//
//  settings_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/providers/theme_provider.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider to react to theme changes
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headlineSmall),
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        color: AppColors.surface,
        child: ListView(
          children: [
            // Display settings section
            SharedWidgets.buildSectionHeader('Display'),

            // Theme toggle
            _buildSettingItem(
              context,
              title: 'Dark Mode',
              subtitle: isDarkMode ? 'On' : 'Off',
              icon: Icons.dark_mode,
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  // Toggle theme
                  ThemeUtils.setTheme(
                      ref, value ? ThemeMode.dark : ThemeMode.light);
                },
                activeColor: AppColors.primary,
              ),
            ),

            // Divider
            Divider(color: AppColors.outline),

            // About section
            SharedWidgets.buildSectionHeader('About'),

            // App version
            _buildSettingItem(
              context,
              title: 'Version',
              subtitle: '0.0.1',
              icon: AppIcons.getIcon('info'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build consistent setting items
  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmall)
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
