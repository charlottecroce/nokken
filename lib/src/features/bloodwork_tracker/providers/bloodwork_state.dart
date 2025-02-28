//
//  bloodwork_state.dart
//  State management for bloodwork using Riverpod
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/services/database_service.dart';

/// State class to handle loading and error states for bloodwork data
class BloodworkState {
  final List<Bloodwork> bloodworkRecords;
  final bool isLoading;
  final String? error;

  const BloodworkState({
    this.bloodworkRecords = const [],
    this.isLoading = false,
    this.error,
  });

  /// Create a new state object with updated fields
  BloodworkState copyWith({
    List<Bloodwork>? bloodworkRecords,
    bool? isLoading,
    String? error,
  }) {
    return BloodworkState(
      bloodworkRecords: bloodworkRecords ?? this.bloodworkRecords,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Pass null to clear error
    );
  }
}

/// Notifier class to handle bloodwork state changes
class BloodworkNotifier extends StateNotifier<BloodworkState> {
  final DatabaseService _databaseService;

  BloodworkNotifier({
    required DatabaseService databaseService,
  })  : _databaseService = databaseService,
        super(const BloodworkState()) {
    // Load bloodwork when initialized
    loadBloodwork();
  }

  /// Load bloodwork from the database
  Future<void> loadBloodwork() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final records = await _databaseService.getAllBloodwork();
      state = state.copyWith(
        bloodworkRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bloodwork: $e',
      );
    }
  }

  /// Add a new bloodwork record to the database
  Future<void> addBloodwork(Bloodwork bloodwork) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Save to database
      await _databaseService.insertBloodwork(bloodwork);

      // Update state immediately with new record
      state = state.copyWith(
        bloodworkRecords: [...state.bloodworkRecords, bloodwork],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add bloodwork: $e',
      );
    }
  }

  /// Update an existing bloodwork record in the database
  Future<void> updateBloodwork(Bloodwork bloodwork) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Update in database
      await _databaseService.updateBloodwork(bloodwork);

      // Update state immediately
      state = state.copyWith(
        bloodworkRecords: state.bloodworkRecords
            .map((record) => record.id == bloodwork.id ? bloodwork : record)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update bloodwork: $e',
      );
    }
  }

  /// Delete a bloodwork record
  Future<void> deleteBloodwork(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Delete from database
      await _databaseService.deleteBloodwork(id);

      // Update state immediately by filtering out the deleted record
      state = state.copyWith(
        bloodworkRecords:
            state.bloodworkRecords.where((record) => record.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete bloodwork: $e',
      );
    }
  }

  /// Helper method to find bloodwork by ID
  Bloodwork? getBloodworkById(String id) {
    try {
      return state.bloodworkRecords.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }
}

//----------------------------------------------------------------------------
// PROVIDER DEFINITIONS
//----------------------------------------------------------------------------

/// Main state notifier provider for bloodwork
final bloodworkStateProvider =
    StateNotifierProvider<BloodworkNotifier, BloodworkState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);

  return BloodworkNotifier(
    databaseService: databaseService,
  );
});

//----------------------------------------------------------------------------
// CONVENIENCE PROVIDERS
//----------------------------------------------------------------------------

/// Provider for accessing the list of bloodwork records
final bloodworkRecordsProvider = Provider<List<Bloodwork>>((ref) {
  return ref.watch(bloodworkStateProvider).bloodworkRecords;
});

/// Provider for checking if bloodwork data is loading
final bloodworkLoadingProvider = Provider<bool>((ref) {
  return ref.watch(bloodworkStateProvider).isLoading;
});

/// Provider for accessing bloodwork loading errors
final bloodworkErrorProvider = Provider<String?>((ref) {
  return ref.watch(bloodworkStateProvider).error;
});

/// Provider for bloodwork records sorted by date (most recent first)
final sortedBloodworkProvider = Provider<List<Bloodwork>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  return [...records]..sort((a, b) => b.date.compareTo(a.date));
});

/// Provider for getting all bloodwork dates for calendar display
final bloodworkDatesProvider = Provider<Set<DateTime>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  return records.map((record) {
    final date = record.date;
    return DateTime(date.year, date.month, date.day);
  }).toSet();
});
