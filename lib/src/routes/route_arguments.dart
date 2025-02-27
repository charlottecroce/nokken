//
// route_arguments.dart
// Classes for passing typed arguments to routes
//
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

/* 
class ArgsCalendarDaily {
  final DateTime selectedDay;

  ArgsCalendarDaily({required this.selectedDay});
}*/

/// Arguments for the medication details screen
/// Passes the medication to be displayed (required)
class ArgsMedicaitonDetails {
  final Medication medication;

  ArgsMedicaitonDetails({required this.medication});
}

/// Arguments for the medication add/edit screen
/// Can be null when adding a new medication
class ArgsMedicaitonAddEdit {
  final Medication? medication;

  ArgsMedicaitonAddEdit({this.medication});
}
