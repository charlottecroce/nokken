//
//  medication_schedule_service.dart
//  Service for handling medication scheduling logic
//
import 'package:flutter/material.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';

class MedicationScheduleService {
  /// Check if a medication is scheduled for the specified date
  static bool isMedicationDueOnDate(Medication medication, DateTime date) {
    // Normalize dates to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(medication.startDate.year,
        medication.startDate.month, medication.startDate.day);

    // Basic date validation - not scheduled before start date
    if (normalizedDate.isBefore(startDate)) {
      return false;
    }

    // Check day of week
    final dayAbbr = DateConstants.dayMap[date.weekday] ?? '';
    if (!medication.daysOfWeek.contains(dayAbbr)) {
      return false;
    }

    // Handle biweekly injections
    if (medication.medicationType == MedicationType.injection &&
        medication.injectionDetails?.frequency == InjectionFrequency.biweekly) {
      return _isBiweeklyScheduled(startDate, normalizedDate);
    }

    return true;
  }

  /// Get all medications due on a specific date
  static List<Medication> getMedicationsForDate(
      List<Medication> allMedications, DateTime date) {
    return allMedications
        .where((med) => isMedicationDueOnDate(med, date))
        .toList();
  }

  /// Helper for determining biweekly schedule
  static bool _isBiweeklyScheduled(DateTime startDate, DateTime checkDate) {
    // Calculate weeks since start
    final daysSince = checkDate.difference(startDate).inDays;
    final weeksSince = daysSince ~/ 7;

    return weeksSince % 2 == 0;
  }

  /// Get all doses due on a specific date
  static List<MedicationDose> getDosesForDate(
      List<Medication> medications, DateTime date) {
    final dueMeds = getMedicationsForDate(medications, date);
    final doses = <MedicationDose>[];

    for (final med in dueMeds) {
      for (final timeSlot in med.timeOfDay) {
        final formattedTime = DateTimeFormatter.formatTimeToAMPM(
            TimeOfDay.fromDateTime(timeSlot));

        doses.add(MedicationDose(
            medicationId: med.id, date: date, timeSlot: formattedTime));
      }
    }

    return doses;
  }

  /// Group medication doses by time slot
  static Map<String, List<Medication>> groupMedicationsByTimeSlot(
      List<Medication> medications) {
    final Map<String, List<Medication>> result = {};

    for (final med in medications) {
      for (final time in med.timeOfDay) {
        final timeStr =
            DateTimeFormatter.formatTimeToAMPM(TimeOfDay.fromDateTime(time));
        if (!result.containsKey(timeStr)) {
          result[timeStr] = [];
        }
        result[timeStr]!.add(med);
      }
    }

    return result;
  }
}
