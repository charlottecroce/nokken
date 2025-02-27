//
//  medication_state.dart
//  State management for medications using Riverpod
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/services/database_service.dart';
import 'package:nokken/src/services/notification_service.dart';

/// State class to handle loading and error states for medication data
class MedicationState {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;

  const MedicationState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  /// Create a new state object with updated fields
  MedicationState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? error,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Pass null to clear error
    );
  }
}

/// Notifier class to handle medication state changes
/// Manages interactions with database and notification services
class MedicationNotifier extends StateNotifier<MedicationState> {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  MedicationNotifier({
    required DatabaseService databaseService,
    required NotificationService notificationService,
  })  : _databaseService = databaseService,
        _notificationService = notificationService,
        super(const MedicationState()) {
    // Load medications when initialized
    loadMedications();
  }

  /// Load medications from the database
  Future<void> loadMedications() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final medications = await _databaseService.getAllMedications();
      state = state.copyWith(
        medications: medications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load medications: $e',
      );
    }
  }

  /// Add a new medication to the database and schedule reminders
  Future<void> addMedication(Medication medication) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Save to database
      await _databaseService.insertMedication(medication);

      // Schedule notifications
      await _notificationService.scheduleMedicationReminders(medication);

      // Update state immediately with new medication
      state = state.copyWith(
        medications: [...state.medications, medication],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add medication: $e',
      );
    }
  }

  /// Update an existing medication in the database and reschedule reminders
  Future<void> updateMedication(Medication medication) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Update in database
      await _databaseService.updateMedication(medication);

      // Reschedule notifications
      await _notificationService.scheduleMedicationReminders(medication);

      // Update state immediately with new medication
      state = state.copyWith(
        medications: state.medications
            .map((med) => med.id == medication.id ? medication : med)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update medication: $e',
      );
    }
  }

  /// Update the quantity of a medication (when taken or reverting a taken status)
  Future<void> updateMedicationQuantity(
      Medication medication, bool taken) async {
    try {
      // Calculate new quantity (decrement if taken, increment if untaken)
      final updatedMed = medication.copyWith(
        currentQuantity: medication.currentQuantity + (taken ? -1 : 1),
      );

      await _databaseService.updateMedication(updatedMed);

      state = state.copyWith(
        medications: state.medications.map((med) {
          return med.id == medication.id ? updatedMed : med;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update medication quantity');
    }
  }

  /// Delete a medication and cancel its reminders
  Future<void> deleteMedication(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Cancel notifications first
      await _notificationService.cancelMedicationReminders(id);

      // Delete from database
      await _databaseService.deleteMedication(id);

      // Update state immediately by filtering out the deleted medication
      state = state.copyWith(
        medications: state.medications.where((med) => med.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete medication: $e',
      );
    }
  }

  /// Helper method to find medication by ID
  Medication? getMedicationById(String id) {
    try {
      return state.medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }
}

//----------------------------------------------------------------------------
// PROVIDER DEFINITIONS
//----------------------------------------------------------------------------

/// Provider for database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Main state notifier provider for medications
final medicationStateProvider =
    StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return MedicationNotifier(
    databaseService: databaseService,
    notificationService: notificationService,
  );
});

//----------------------------------------------------------------------------
// CONVENIENCE PROVIDERS
//----------------------------------------------------------------------------

/// Provider for accessing the list of medications
final medicationsProvider = Provider<List<Medication>>((ref) {
  return ref.watch(medicationStateProvider).medications;
});

/// Provider for checking if medications are loading
final medicationsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(medicationStateProvider).isLoading;
});

/// Provider for accessing medication loading errors
final medicationsErrorProvider = Provider<String?>((ref) {
  return ref.watch(medicationStateProvider).error;
});

/// Provider for medications that need to be refilled
final medicationsByNeedRefillProvider = Provider<List<Medication>>((ref) {
  return ref
      .watch(medicationStateProvider)
      .medications
      .where((med) => med.needsRefill())
      .toList();
});

/// Provider for sorted medications (by name)
final sortedMedicationsProvider = Provider<List<Medication>>((ref) {
  final medications = ref.watch(medicationStateProvider).medications;
  return [...medications]..sort((a, b) => a.name.compareTo(b.name));
});
