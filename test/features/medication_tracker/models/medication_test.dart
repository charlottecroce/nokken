// test/features/medication_tracker/models/medication_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

void main() {
  group('Medication', () {
    test('needsRefill should return true when quantity is below threshold', () {
      // Setup - using minimal valid parameters
      final medication = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 3,
        refillThreshold: 5,
        medicationType: MedicationType.oral,
      );

      // Test and verify
      expect(medication.needsRefill(), true);
    });

    test('needsRefill should return false when quantity is above threshold',
        () {
      // Setup - using minimal valid parameters
      final medication = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.oral,
      );

      // Test and verify
      expect(medication.needsRefill(), false);
    });

    test('every medication has a unique ID', () {
      // Create two medications with identical properties
      final medication1 = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.oral,
      );

      final medication2 = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.oral,
      );

      // Verify each has a unique ID
      expect(medication1.id, isNot(equals(medication2.id)));
      expect(medication1.id, isNotEmpty);
      expect(medication2.id, isNotEmpty);
    });
  });
}
