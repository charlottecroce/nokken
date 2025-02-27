//
//  main_screen.dart
//  Main container screen with bottom navigation
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/settings/screens/settings_screen.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/features/scheduler/screens/daily_tracker_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_list_screen.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

/// Provider to track the current navigation index
/// Default to index 2 (daily tracker)
final navigationIndexProvider = StateProvider<int>((ref) => 2);

/// Main application screen
/// Serves as the container for the main functional screens
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    /// Placeholder for upcoming features
    Widget buildComingSoon(String feature) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64),
            SharedWidgets.verticalSpace(),
            Text(
              '$feature Coming Soon',
              style: AppTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    // List of all screens accessible from the bottom navigation
    final screens = [
      const MedicationListScreen(),
      buildComingSoon('Feature 1'),
      DailyTrackerScreen(),
      buildComingSoon('Feature 2'),
      const SettingsScreen()
    ];

    return Scaffold(
      // Display the currently selected screen
      body: screens[currentIndex],

      // Bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.onPrimary,
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          destinations: [
            // Medications tab
            NavigationDestination(
              icon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getOutlined('medication')),
              ),
              selectedIcon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getFilled('medication')),
              ),
              label: 'Medications',
            ),
            // Placeholder for future feature
            NavigationDestination(
              icon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getOutlined('menu')),
              ),
              selectedIcon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getFilled('menu')),
              ),
              label: 'coming soon',
            ),
            // Daily tracker tab
            NavigationDestination(
              icon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getOutlined('calendar')),
              ),
              selectedIcon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getFilled('calendar')),
              ),
              label: 'Daily Tracker',
            ),
            // Placeholder for future feature
            NavigationDestination(
              icon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getOutlined('menu')),
              ),
              selectedIcon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getFilled('menu')),
              ),
              label: 'coming soon',
            ),
            // Settings tab
            NavigationDestination(
              icon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getOutlined('settings')),
              ),
              selectedIcon: Padding(
                padding: AppTheme.navigationBarPadding,
                child: Icon(AppIcons.getFilled('settings')),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
