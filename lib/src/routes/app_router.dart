//
// app_router.dart
// Centralized navigation router
//
import 'package:flutter/material.dart';
import 'route_names.dart';
import 'package:nokken/src/routes/route_arguments.dart';
import 'package:nokken/src/features/scheduler/screens/daily_tracker_screen.dart';
import 'package:nokken/src/features/scheduler/screens/calendar_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_list_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_detail_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/add_edit_medication_screen.dart';
import 'package:nokken/src/features/settings/screens/settings_screen.dart';

/// Router class that handles all navigation within the app
class AppRouter {
  /// Called by MaterialApp's onGenerateRoute property
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.dailyTracker:
        return MaterialPageRoute(builder: (_) => DailyTrackerScreen());

      case RouteNames.calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case RouteNames.medicationList:
        return MaterialPageRoute(builder: (_) => const MedicationListScreen());

      case RouteNames.medicationDetails:
        final args = settings.arguments as ArgsMedicaitonDetails;
        return MaterialPageRoute(
          builder: (_) => MedicationDetailScreen(
            medication: args.medication,
          ),
        );

      case RouteNames.medicationAddEdit:
        if (settings.arguments == null) {
          return MaterialPageRoute(
            builder: (_) =>
                const AddEditMedicationScreen(), // No args = Add new
          );
        }
        final args = settings.arguments as ArgsMedicaitonAddEdit;
        return MaterialPageRoute(
          builder: (_) => AddEditMedicationScreen(
            medication: args.medication,
          ),
        );

      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Fallback for unknown routes
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
