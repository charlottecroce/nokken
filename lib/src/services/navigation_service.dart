//
//  navigation_service.dart
//
import 'package:flutter/material.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/routes/route_arguments.dart';
import 'package:nokken/src/routes/route_names.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_detail_screen.dart';

class NavigationService {
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  static bool goBackWithResult<T>(BuildContext context, T result) {
    Navigator.of(context).pop(result);
    return result as bool;
  }

  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void goToDailyTracker(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.dailyTracker);
  }

  static void goToMedicationList(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.medicationList);
  }

  static void goToMedicationDetails(BuildContext context,
      {required Medication medication}) {
    Navigator.pushNamed(
      context,
      RouteNames.medicationDetails,
      arguments: ArgsMedicaitonDetails(medication: medication),
    );
  }

  static void goToMedicationAddEdit(BuildContext context,
      {Medication? medication}) {
    Navigator.pushNamed(
      context,
      RouteNames.medicationAddEdit,
      arguments: ArgsMedicaitonAddEdit(medication: medication),
    );
  }

  // Returning a Future allows a '.then(...' action. needed to load DB when calendar pops
  static Future<void> goToCalendar(BuildContext context) {
    return Navigator.pushNamed(context, RouteNames.calendar);
  }

  static void goToSettings(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.settings);
  }

  static void showMedicaitonDetails(
      BuildContext context, Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    );
  }
}
