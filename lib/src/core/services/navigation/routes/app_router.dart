//
// app_router.dart
// Centralized navigation router
//
import 'package:flutter/material.dart';
import 'route_names.dart';
import 'package:nokken/src/core/services/navigation/routes/route_arguments.dart';
import 'package:nokken/src/features/scheduler/screens/daily_tracker_screen.dart';
import 'package:nokken/src/features/scheduler/screens/calendar_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_list_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_detail_screen.dart';
import 'package:nokken/src/features/medication_tracker/screens/add_edit_medication_screen.dart';
import 'package:nokken/src/features/bloodwork_tracker/screens/bloodwork_list_screen.dart';
import 'package:nokken/src/features/bloodwork_tracker/screens/add_edit_bloodwork_screen.dart';
import 'package:nokken/src/features/bloodwork_tracker/screens/bloodwork_graph_screen.dart';
import 'package:nokken/src/features/bloodwork_tracker/screens/blood_level_list_screen.dart';
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

      case RouteNames.bloodworkList:
        return MaterialPageRoute(builder: (_) => const BloodworkListScreen());

      case RouteNames.bloodLevelList:
        return MaterialPageRoute(builder: (_) => const BloodLevelListScreen());

      case RouteNames.bloodworkAddEdit:
        if (settings.arguments == null) {
          return MaterialPageRoute(
            builder: (_) => const AddEditBloodworkScreen(), // No args = Add new
          );
        }
        final args = settings.arguments as ArgsBloodworkAddEdit;
        return MaterialPageRoute(
          builder: (_) => AddEditBloodworkScreen(
            bloodwork: args.bloodwork,
          ),
        );

      case RouteNames.bloodworkGraph:
        if (settings.arguments == null) {
          return MaterialPageRoute(
              builder: (_) => const BloodworkGraphScreen());
        }
        final args = settings.arguments as ArgsBloodworkGraph;
        return MaterialPageRoute(
          builder: (_) => BloodworkGraphScreen(
            selectedHormone: args.selectedHormone,
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
