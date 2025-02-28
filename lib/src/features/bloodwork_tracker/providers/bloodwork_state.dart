//
//  bloodwork_state.dart
//  State management for bloodwork using Riverpod
//

import 'package:flutter/material.dart';
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

/// Provider for all medical records sorted by date (most recent first)
final sortedBloodworkProvider = Provider<List<Bloodwork>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  // Sort by date (most recent first)
  return [...records]..sort((a, b) => b.date.compareTo(a.date));
});

/// Provider for bloodwork-type records only (for graph display)
final bloodworkTypeRecordsProvider = Provider<List<Bloodwork>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  // Filter only records that are bloodwork type for hormone graphs
  final bloodworkRecords = records
      .where((record) => record.appointmentType == AppointmentType.bloodwork)
      .toList();

  // Sort by date (most recent first)
  return [...bloodworkRecords]..sort((a, b) => b.date.compareTo(a.date));
});

/// Provider for getting all bloodwork dates for calendar display
final bloodworkDatesProvider = Provider<Set<DateTime>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  return records.map((record) {
    final date = record.date;
    return DateTime(date.year, date.month, date.day);
  }).toSet();
});

/// Provider that groups and sorts bloodwork records into upcoming, today, and past sections
final groupedBloodworkProvider = Provider<Map<String, List<Bloodwork>>>((ref) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Initialize the result map with empty lists
  final result = {
    'upcoming': <Bloodwork>[],
    'today': <Bloodwork>[],
    'past': <Bloodwork>[],
  };

  // Categorize each record
  for (final record in records) {
    final recordDate =
        DateTime(record.date.year, record.date.month, record.date.day);

    if (recordDate.isAfter(today)) {
      result['upcoming']!.add(record);
    } else if (recordDate.isAtSameMomentAs(today)) {
      result['today']!.add(record);
    } else {
      result['past']!.add(record);
    }
  }

  // Sort upcoming appointments (earliest first)
  result['upcoming']!.sort((a, b) => a.date.compareTo(b.date));

  // Sort today's appointments (earliest first)
  result['today']!.sort((a, b) => a.date.compareTo(b.date));

  // Sort past appointments (latest first)
  result['past']!.sort((a, b) => b.date.compareTo(a.date));

  return result;
});

/// Provider for getting different colors for different appointment types in calendar
final appointmentTypeColorsProvider =
    Provider<Map<AppointmentType, Color>>((ref) {
  return {
    AppointmentType.bloodwork: Colors.red,
    AppointmentType.appointment: Colors.blue,
    AppointmentType.surgery: Colors.purple,
  };
});

/// Provider for filtered bloodwork records by appointment type
final filteredBloodworkByTypeProvider =
    Provider.family<List<Bloodwork>, AppointmentType>((ref, type) {
  final records = ref.watch(bloodworkStateProvider).bloodworkRecords;
  return records.where((record) => record.appointmentType == type).toList();
});

/// Provider that extracts all unique hormone types from records
final hormoneTypesProvider = Provider<List<String>>((ref) {
  final records = ref.watch(bloodworkTypeRecordsProvider);
  final Set<String> hormoneTypes = {};

  // Extract from readings
  for (final record in records) {
    for (final reading in record.hormoneReadings) {
      hormoneTypes.add(reading.name);
    }
  }

  // Add legacy fields if present
  if (records.any((record) => record.estrogen != null)) {
    hormoneTypes.add('Estrogen');
  }
  if (records.any((record) => record.testosterone != null)) {
    hormoneTypes.add('Testosterone');
  }

  // Sort alphabetically
  final sortedTypes = hormoneTypes.toList()..sort();
  return sortedTypes;
});

/// Provider for getting all records for a specific hormone type
final hormoneRecordsProvider =
    Provider.family<List<MapEntry<DateTime, double>>, String>(
        (ref, hormoneName) {
  final records = ref.watch(bloodworkTypeRecordsProvider);
  final List<MapEntry<DateTime, double>> readings = [];

  for (final record in records) {
    // First check in hormone readings
    for (final reading in record.hormoneReadings) {
      if (reading.name == hormoneName) {
        readings.add(MapEntry(record.date, reading.value));
      }
    }

    // For backward compatibility
    if (hormoneName == 'Estrogen' && record.estrogen != null) {
      readings.add(MapEntry(record.date, record.estrogen!));
    } else if (hormoneName == 'Testosterone' && record.testosterone != null) {
      readings.add(MapEntry(record.date, record.testosterone!));
    }
  }

  // Sort by date (oldest first for charts)
  readings.sort((a, b) => a.key.compareTo(b.key));
  return readings;
});

/// Provider to get the most recent value for a specific hormone
final latestHormoneValueProvider =
    Provider.family<double?, String>((ref, hormoneName) {
  final readings = ref.watch(hormoneRecordsProvider(hormoneName));
  if (readings.isEmpty) return null;

  // Sort by date descending (most recent first)
  final sortedReadings = [...readings];
  sortedReadings.sort((a, b) => b.key.compareTo(a.key));

  return sortedReadings.first.value;
});

/// Provider to get the unit for a specific hormone type
final hormoneUnitProvider = Provider.family<String, String>((ref, hormoneName) {
  final records = ref.watch(bloodworkTypeRecordsProvider);

  // First try to find it in the data
  for (final record in records) {
    for (final reading in record.hormoneReadings) {
      if (reading.name == hormoneName) {
        return reading.unit;
      }
    }
  }

  // Fall back to default units
  switch (hormoneName) {
    case 'Estrogen':
      return 'pg/mL';
    case 'Testosterone':
      return 'ng/dL';
    default:
      return HormoneTypes.getDefaultUnit(hormoneName);
  }
});
