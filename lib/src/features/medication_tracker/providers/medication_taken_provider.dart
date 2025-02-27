//
//  medication_taken_provider.dart
//  Provider to manage taken medications with database persistence
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/features/medication_tracker/services/medication_schedule_service.dart';
import 'package:nokken/src/services/database_service.dart';

/// Notifier for tracking which medications have been taken
class MedicationTakenNotifier extends StateNotifier<Set<String>> {
  final DatabaseService _databaseService;

  MedicationTakenNotifier({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super({});

  /// Load taken medications for a specific date
  Future<void> loadTakenMedicationsForDate(DateTime date) async {
    try {
      final takenMeds = await _databaseService.getTakenMedicationsForDate(date);
      state = takenMeds;
    } catch (e) {
      // Handle error - perhaps log it, but continue with empty set
      state = {};
    }
  }

  /// Set a medication as taken or not taken
  Future<void> setMedicationTaken(MedicationDose dose, bool taken) async {
    final key = dose.toKey();

    try {
      // Update database
      await _databaseService.setMedicationTaken(
          dose.medicationId, dose.date, dose.timeSlot, taken);

      // Update state
      if (taken) {
        state = {...state, key};
      } else {
        state = {...state}..remove(key);
      }
    } catch (e) {
      // If database update fails, don't update state
      // Could add error handling here
    }
  }

  /// Clear expired data (optional maintenance function)
  Future<void> clearOldData(int olderThanDays) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
    try {
      await _databaseService.deleteTakenMedicationsOlderThan(cutoffDate);
      // No need to update state since we don't track old data in memory
    } catch (e) {
      // Handle error
    }
  }
}

//----------------------------------------------------------------------------
// PROVIDER DEFINITIONS
//----------------------------------------------------------------------------

/// Provider for tracking which medications have been taken
final medicationTakenProvider =
    StateNotifierProvider<MedicationTakenNotifier, Set<String>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return MedicationTakenNotifier(databaseService: databaseService);
});

/// Provider to get medications scheduled for a specific date
final medicationsForDateProvider =
    Provider.family<List<Medication>, DateTime>((ref, date) {
  final allMedications = ref.watch(medicationsProvider);
  return MedicationScheduleService.getMedicationsForDate(allMedications, date);
});

/// Provider to get medication doses scheduled for a specific date
final dosesForDateProvider =
    Provider.family<List<MedicationDose>, DateTime>((ref, date) {
  final medications = ref.watch(medicationsForDateProvider(date));
  return MedicationScheduleService.getDosesForDate(medications, date);
});

/// Provider to check if a specific medication dose is taken
final isDoseTakenProvider = Provider.family<bool, MedicationDose>((ref, dose) {
  final takenMedications = ref.watch(medicationTakenProvider);
  return takenMedications.contains(dose.toKey());
});

/// Provider that groups medications by time slot for a specific date
final medicationsByTimeSlotProvider =
    Provider.family<Map<String, List<Medication>>, DateTime>((ref, date) {
  final medications = ref.watch(medicationsForDateProvider(date));
  return MedicationScheduleService.groupMedicationsByTimeSlot(medications);
});
