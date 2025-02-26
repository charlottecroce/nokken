//
//  main_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/settings/screens/settings_screen.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/features/scheduler/screens/daily_tracker_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_list_screen.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

// Provider to track the current navigation index
final navigationIndexProvider =
    StateProvider<int>((ref) => 2); // Default to daily tracker

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    // Placeholder widget for coming soon screens
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

    // List of all screens
    final screens = [
      const MedicationListScreen(),
      buildComingSoon('Feature 1'),
      DailyTrackerScreen(),
      buildComingSoon('Feature 2'),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
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
