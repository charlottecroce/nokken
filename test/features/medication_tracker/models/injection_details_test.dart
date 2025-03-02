// test/features/medication_tracker/models/injection_details_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

void main() {
  group('InjectionDetails', () {
    // Test constructor
    test('should create valid injection details', () {
      // Arrange & Act - create injection details
      final details = InjectionDetails(
        drawingNeedleType: '18G 1.5"',
        drawingNeedleCount: 10,
        drawingNeedleRefills: 2,
        injectingNeedleType: '25G 1"',
        injectingNeedleCount: 8,
        injectingNeedleRefills: 2,
        injectionSiteNotes: 'Rotate injection sites',
        frequency: InjectionFrequency.weekly,
      );

      // Assert - verify properties
      expect(details.drawingNeedleType, equals('18G 1.5"'));
      expect(details.drawingNeedleCount, equals(10));
      expect(details.drawingNeedleRefills, equals(2));
      expect(details.injectingNeedleType, equals('25G 1"'));
      expect(details.injectingNeedleCount, equals(8));
      expect(details.injectingNeedleRefills, equals(2));
      expect(details.injectionSiteNotes, equals('Rotate injection sites'));
      expect(details.frequency, equals(InjectionFrequency.weekly));
    });

    // Test JSON conversion
    test('should convert to and from JSON correctly', () {
      // Arrange - create injection details
      final original = InjectionDetails(
        drawingNeedleType: '18G 1.5"',
        drawingNeedleCount: 10,
        drawingNeedleRefills: 2,
        injectingNeedleType: '25G 1"',
        injectingNeedleCount: 8,
        injectingNeedleRefills: 2,
        injectionSiteNotes: 'Rotate injection sites',
        frequency: InjectionFrequency.weekly,
      );

      // Act - convert to JSON and back
      final json = original.toJson();
      final restored = InjectionDetails.fromJson(json);

      // Assert - verify properties match
      expect(restored.drawingNeedleType, equals(original.drawingNeedleType));
      expect(restored.drawingNeedleCount, equals(original.drawingNeedleCount));
      expect(
          restored.drawingNeedleRefills, equals(original.drawingNeedleRefills));
      expect(
          restored.injectingNeedleType, equals(original.injectingNeedleType));
      expect(
          restored.injectingNeedleCount, equals(original.injectingNeedleCount));
      expect(restored.injectingNeedleRefills,
          equals(original.injectingNeedleRefills));
      expect(restored.injectionSiteNotes, equals(original.injectionSiteNotes));
      expect(restored.frequency, equals(original.frequency));
    });

    test('should handle missing frequency in JSON', () {
      // Arrange - create incomplete JSON without frequency
      final incompleteJson = {
        'drawingNeedleType': '18G',
        'drawingNeedleCount': 10,
        'drawingNeedleRefills': 2,
        'injectingNeedleType': '25G',
        'injectingNeedleCount': 8,
        'injectingNeedleRefills': 2,
        'injectionSiteNotes': 'Notes',
        // Missing frequency
      };

      // Act - create from incomplete JSON
      final details = InjectionDetails.fromJson(incompleteJson);

      // Assert - default to weekly frequency
      expect(details.frequency, equals(InjectionFrequency.weekly));
    });

    // Test integration with Medication
    test('should be properly included in Medication', () {
      // Arrange - create injection details
      final injectionDetails = InjectionDetails(
        drawingNeedleType: '18G 1.5"',
        drawingNeedleCount: 10,
        drawingNeedleRefills: 2,
        injectingNeedleType: '25G 1"',
        injectingNeedleCount: 8,
        injectingNeedleRefills: 2,
        injectionSiteNotes: 'Rotate injection sites',
        frequency: InjectionFrequency.biweekly,
      );

      // Act - create medication with these details
      final medication = Medication(
        name: 'Test Injectable',
        dosage: '100mg',
        startDate: DateTime(2023, 6, 15),
        frequency: 1,
        timeOfDay: [DateTime(2023, 6, 15, 9, 0)],
        daysOfWeek: {'Su'},
        currentQuantity: 5,
        refillThreshold: 2,
        medicationType: MedicationType.injection,
        injectionDetails: injectionDetails,
      );

      // Assert - verify injection details are properly associated
      expect(medication.injectionDetails, isNotNull);
      expect(medication.injectionDetails?.frequency,
          equals(InjectionFrequency.biweekly));
      expect(
          medication.injectionDetails?.drawingNeedleType, equals('18G 1.5"'));
    });

    // Test that medication validates injection details
    test('injection medication should validate frequency constraints', () {
      // Arrange & Act - try to create biweekly injection with frequency > 1
      invalidMedication() => Medication(
            name: 'Test Injectable',
            dosage: '100mg',
            startDate: DateTime(2023, 6, 15),
            frequency: 2, // Frequency > 1 not allowed for biweekly
            timeOfDay: [
              DateTime(2023, 6, 15, 9, 0),
              DateTime(2023, 6, 15, 21, 0)
            ],
            daysOfWeek: {'Su'},
            currentQuantity: 5,
            refillThreshold: 2,
            medicationType: MedicationType.injection,
            injectionDetails: InjectionDetails(
              drawingNeedleType: '18G',
              drawingNeedleCount: 10,
              drawingNeedleRefills: 2,
              injectingNeedleType: '25G',
              injectingNeedleCount: 8,
              injectingNeedleRefills: 2,
              injectionSiteNotes: 'Notes',
              frequency: InjectionFrequency.biweekly,
            ),
          );

      // Assert - expect exception due to validation failure
      expect(invalidMedication, throwsA(isA<MedicationException>()));
    });
  });
}
