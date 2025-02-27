//
//  medication_dose.dart
//  Model representing a specific dose of medication on a specific date and time
//
import 'package:flutter/material.dart';

class MedicationDose {
  final String medicationId;
  final DateTime date;
  final String timeSlot;

  /// Create a medication dose with normalized date (no time component)
  MedicationDose(
      {required this.medicationId,
      required DateTime date,
      required this.timeSlot})
      : date = DateTime(date.year, date.month, date.day);

  /// Override equality for proper comparison in Sets and Maps
  @override
  bool operator ==(Object other) =>
      other is MedicationDose &&
      other.medicationId == medicationId &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day &&
      other.timeSlot == timeSlot;

  @override
  int get hashCode => Object.hash(
      medicationId, DateTime(date.year, date.month, date.day), timeSlot);

  /// Convert to string key format used in database
  String toKey() => '$medicationId-${date.toIso8601String()}-$timeSlot';

  /// Create a dose object from a string key
  static MedicationDose fromKey(String key) {
    final parts = key.split('-');
    // Handle medication IDs that may contain hyphens
    final dateAndTimeStart = key.lastIndexOf('-', key.lastIndexOf('-') - 1);
    final id = key.substring(0, dateAndTimeStart);
    final remaining = key.substring(dateAndTimeStart + 1);
    final remainingParts = remaining.split('-');

    final dateStr = remainingParts[0];
    final timeSlot = remainingParts[1];

    return MedicationDose(
        medicationId: id, date: DateTime.parse(dateStr), timeSlot: timeSlot);
  }
}
