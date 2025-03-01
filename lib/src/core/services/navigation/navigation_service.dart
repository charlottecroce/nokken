//
//  navigation_service.dart
//  Utility service for app-wide navigation functions
//
import 'package:flutter/material.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/core/services/navigation/routes/route_arguments.dart';
import 'package:nokken/src/core/services/navigation/routes/route_names.dart';
import 'package:nokken/src/features/medication_tracker/screens/medication_detail_screen.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';

/// Abstracts navigation logic for consistent behavior throughout the app
class NavigationService {
  /// Navigate back to the previous screen
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Navigate back with a result value
  /// Used for dialogs and forms that return data
  static bool goBackWithResult<T>(BuildContext context, T result) {
    Navigator.of(context).pop(result);
    return result as bool;
  }

  /// Return to the home screen (clears navigation stack)
  /// Might need to be updated to stop popping when reaching designated routes
  /// (e.x. pop until calendar screen, rather than until daily tracker, which is under calendar)
  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to the daily tracker screen
  static void goToDailyTracker(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.dailyTracker);
  }

  /// Navigate to calendar screen
  /// Returns a Future to allow a .then(), which is used to update taken DB when exiting calendar to daily tracker
  static Future<void> goToCalendar(BuildContext context) {
    return Navigator.pushNamed(context, RouteNames.calendar);
  }

  /// Navigate to the medication list screen
  static void goToMedicationList(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.medicationList);
  }

  /// Navigate to medication details screen
  static void goToMedicationDetails(BuildContext context,
      {required Medication medication}) {
    Navigator.pushNamed(
      context,
      RouteNames.medicationDetails,
      arguments: ArgsMedicaitonDetails(medication: medication),
    );
  }

  /// Navigate to add/edit medication screen
  /// If medication is null, screen opens in 'add' mode
  /// If medication is provided, screen opens in 'edit' mode
  static void goToMedicationAddEdit(BuildContext context,
      {Medication? medication}) {
    Navigator.pushNamed(
      context,
      RouteNames.medicationAddEdit,
      arguments: ArgsMedicaitonAddEdit(medication: medication),
    );
  }

  /// Navigate to bloodwork list screen
  static void goToBloodworkList(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.bloodworkList);
  }

  /// Navigate to bloodwork overview screen
  static void goToBloodLevelList(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.bloodLevelList);
  }

  /// Navigate to bloodwork graph screen
  static void goToBloodworkGraph(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.bloodworkGraph);
  }

  /// Navigate to bloodwork graph screen for a specific hormone
  static void goToBloodworkGraphWithHormone(
      BuildContext context, String hormoneName) {
    Navigator.pushNamed(
      context,
      RouteNames.bloodworkGraph,
      arguments: ArgsBloodworkGraph(selectedHormone: hormoneName),
    );
  }

  /// Navigate to add/edit bloodwork screen
  /// If bloodwork is null, screen opens in 'add' mode
  /// If bloodwork is provided, screen opens in 'edit' mode
  static void goToBloodworkAddEdit(BuildContext context,
      {Bloodwork? bloodwork}) {
    Navigator.pushNamed(
      context,
      RouteNames.bloodworkAddEdit,
      arguments: ArgsBloodworkAddEdit(bloodwork: bloodwork),
    );
  }

  /// Navigate to settings screen
  static void goToSettings(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.settings);
  }
}
