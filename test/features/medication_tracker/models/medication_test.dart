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
        oralSubtype: OralSubtype.tablets,
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
        oralSubtype: OralSubtype.tablets,
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
        oralSubtype: OralSubtype.tablets,
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
        oralSubtype: OralSubtype.tablets,
      );

      // Verify each has a unique ID
      expect(medication1.id, isNot(equals(medication2.id)));
      expect(medication1.id, isNotEmpty);
      expect(medication2.id, isNotEmpty);
    });

    test('should validate that oral medications have oral subtype', () {
      // Should succeed
      final validOral = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.oral,
        oralSubtype: OralSubtype.tablets,
      );

      expect(validOral.oralSubtype, equals(OralSubtype.tablets));

      // Should throw exception when oral medication has no subtype
      expect(
          () => Medication(
                name: 'Test Med',
                dosage: '10mg',
                startDate: DateTime(2023, 1, 1),
                frequency: 1,
                timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
                daysOfWeek: {'M'},
                currentQuantity: 10,
                refillThreshold: 5,
                medicationType: MedicationType.oral,
                oralSubtype: null,
              ),
          throwsA(isA<MedicationException>()));
    });

    test('should validate that topical medications have topical subtype', () {
      // Should succeed
      final validTopical = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.topical,
        topicalSubtype: TopicalSubtype.gel,
      );

      expect(validTopical.topicalSubtype, equals(TopicalSubtype.gel));

      // Should throw exception when topical medication has no subtype
      expect(
          () => Medication(
                name: 'Test Med',
                dosage: '10mg',
                startDate: DateTime(2023, 1, 1),
                frequency: 1,
                timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
                daysOfWeek: {'M'},
                currentQuantity: 10,
                refillThreshold: 5,
                medicationType: MedicationType.topical,
                topicalSubtype: null,
              ),
          throwsA(isA<MedicationException>()));
    });

    test('patch medication does not require subtypes', () {
      // Should succeed
      final validPatch = Medication(
        name: 'Test Med',
        dosage: '10mg',
        startDate: DateTime(2023, 1, 1),
        frequency: 1,
        timeOfDay: [DateTime(2023, 1, 1, 8, 0)],
        daysOfWeek: {'M'},
        currentQuantity: 10,
        refillThreshold: 5,
        medicationType: MedicationType.patch,
      );

      expect(validPatch.medicationType, equals(MedicationType.patch));
      expect(validPatch.oralSubtype, isNull);
      expect(validPatch.topicalSubtype, isNull);
      expect(validPatch.injectionDetails, isNull);
    });

    test('doctor and pharmacy fields are optional', () {
      // Create medication with doctor and pharmacy
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
        oralSubtype: OralSubtype.tablets,
        doctor: 'Dr. Smith',
        pharmacy: 'City Pharmacy',
      );

      // Verify fields are set
      expect(medication.doctor, 'Dr. Smith');
      expect(medication.pharmacy, 'City Pharmacy');
    });

    test('JSON conversion preserves all fields', () {
      // Create a complex medication object
      final original = Medication(
        name: 'Test Injectable',
        dosage: '100mg',
        startDate: DateTime(2023, 6, 15),
        frequency: 1,
        timeOfDay: [DateTime(2023, 6, 15, 9, 0)],
        daysOfWeek: {'Su'},
        currentQuantity: 5,
        refillThreshold: 2,
        medicationType: MedicationType.injection,
        doctor: 'Dr. Jones',
        pharmacy: 'Medical Supply Store',
        injectionDetails: InjectionDetails(
          drawingNeedleType: '18G',
          drawingNeedleCount: 10,
          drawingNeedleRefills: 2,
          injectingNeedleType: '25G',
          injectingNeedleCount: 8,
          injectingNeedleRefills: 2,
          syringeType: '3ml Luer Lock',
          syringeCount: 12,
          syringeRefills: 3,
          injectionSiteNotes: 'Rotate injection sites',
          frequency: InjectionFrequency.biweekly,
          subtype: InjectionSubtype.intramuscular,
        ),
      );

      // Convert to JSON and back
      final json = original.toJson();
      final restored = Medication.fromJson(json);

      // Verify all fields are preserved
      expect(restored.name, equals(original.name));
      expect(restored.dosage, equals(original.dosage));
      expect(restored.medicationType, equals(original.medicationType));
      expect(restored.doctor, equals(original.doctor));
      expect(restored.pharmacy, equals(original.pharmacy));

      // Check injection details
      expect(restored.injectionDetails?.syringeType, equals('3ml Luer Lock'));
      expect(restored.injectionDetails?.syringeCount, equals(12));
      expect(restored.injectionDetails?.syringeRefills, equals(3));
      expect(restored.injectionDetails?.subtype,
          equals(InjectionSubtype.intramuscular));
    });
  });
}
