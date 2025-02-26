import 'package:nokken/src/features/medication_tracker/models/medication.dart';

class ArgsCalendarDaily {
  final DateTime selectedDay;

  ArgsCalendarDaily({required this.selectedDay});
}

class ArgsMedicaitonDetails {
  final Medication medication;

  ArgsMedicaitonDetails({required this.medication});
}

class ArgsMedicaitonAddEdit {
  final Medication? medication;

  ArgsMedicaitonAddEdit({this.medication});
}
