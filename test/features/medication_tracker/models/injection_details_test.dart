// test/features/medication_tracker/models/injection_details_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

void main() {
  group('InjectionDetails', () {
    // Test constructor
    test('should create valid injection details with new fields', () {
      // Arrange & Act - create injection details with all fields
      final details = InjectionDetails(
        drawingNeedleType: '18G 1.5"',
        drawingNeedleCount: 10,
        drawingNeedleRefills: 2,
        injectingNeedleType: '25G 1"',
        injectingNeedleCount: 8,
        injectingNeedleRefills: 2,
        syringeType: '3ml Luer Lock',
        syringeCount: 12,
        syringeRefills: 3,
        injectionSiteNotes: 'Rotate injection sites',
        frequency: InjectionFrequency.weekly,
        subtype: InjectionSubtype.intramuscular,
      );

      // Assert - verify properties
      expect(details.drawingNeedleType, equals('18G 1.5"'));
      expect(details.drawingNeedleCount, equals(10));
      expect(details.drawingNeedleRefills, equals(2));
      expect(details.injectingNeedleType, equals('25G 1"'));
      expect(details.injectingNeedleCount, equals(8));
      expect(details.injectingNeedleRefills, equals(2));
      expect(details.syringeType, equals('3ml Luer Lock'));
      expect(details.syringeCount, equals(12));
      expect(details.syringeRefills, equals(3));
      expect(details.injectionSiteNotes, equals('Rotate injection sites'));
      expect(details.frequency, equals(InjectionFrequency.weekly));
      expect(details.subtype, equals(InjectionSubtype.intramuscular));
    });

    // Test JSON conversion
    test('should convert to and from JSON correctly including new fields', () {
      // Arrange - create injection details
      final original = InjectionDetails(
        drawingNeedleType: '18G 1.5"',
        drawingNeedleCount: 10,
        drawingNeedleRefills: 2,
        injectingNeedleType: '25G 1"',
        injectingNeedleCount: 8,
        injectingNeedleRefills: 2,
        syringeType: '3ml Luer Lock',
        syringeCount: 12,
        syringeRefills: 3,
        injectionSiteNotes: 'Rotate injection sites',
        frequency: InjectionFrequency.weekly,
        subtype: InjectionSubtype.subcutaneous,
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
      expect(restored.syringeType, equals(original.syringeType));
      expect(restored.syringeCount, equals(original.syringeCount));
      expect(restored.syringeRefills, equals(original.syringeRefills));
      expect(restored.injectionSiteNotes, equals(original.injectionSiteNotes));
      expect(restored.frequency, equals(original.frequency));
      expect(restored.subtype, equals(original.subtype));
    });

    test('should handle missing new fields in JSON with defaults', () {
      // Arrange - create incomplete JSON without new fields
      final incompleteJson = {
        'drawingNeedleType': '18G',
        'drawingNeedleCount': 10,
        'drawingNeedleRefills': 2,
        'injectingNeedleType': '25G',
        'injectingNeedleCount': 8,
        'injectingNeedleRefills': 2,
        'injectionSiteNotes': 'Notes',
        'frequency': 'InjectionFrequency.weekly',
        // Missing syringeType, syringeCount, syringeRefills, subtype
      };

      // Act - create from incomplete JSON
      final details = InjectionDetails.fromJson(incompleteJson);

      // Assert - verify defaults are used where fields are missing
      expect(details.syringeType, equals(''));
      expect(details.syringeCount, equals(0));
      expect(details.syringeRefills, equals(0));
      expect(details.subtype, equals(InjectionSubtype.intramuscular));
    });

    // Test integration with Medication
    test('should support all injection subtypes in Medication', () {
      // Arrange & Act - create medications with different subtypes
      final imInjection = Medication(
        name: 'IM Injectable',
        dosage: '100mg',
        startDate: DateTime(2023, 6, 15),
        frequency: 1,
        timeOfDay: [DateTime(2023, 6, 15, 9, 0)],
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
          syringeType: '3ml',
          syringeCount: 10,
          syringeRefills: 2,
          injectionSiteNotes: 'Notes',
          frequency: InjectionFrequency.weekly,
          subtype: InjectionSubtype.intramuscular,
        ),
      );

      final scInjection = Medication(
        name: 'SC Injectable',
        dosage: '50mg',
        startDate: DateTime(2023, 6, 15),
        frequency: 1,
        timeOfDay: [DateTime(2023, 6, 15, 9, 0)],
        daysOfWeek: {'Su'},
        currentQuantity: 5,
        refillThreshold: 2,
        medicationType: MedicationType.injection,
        injectionDetails: InjectionDetails(
          drawingNeedleType: '22G',
          drawingNeedleCount: 10,
          drawingNeedleRefills: 2,
          injectingNeedleType: '27G',
          injectingNeedleCount: 8,
          injectingNeedleRefills: 2,
          syringeType: '1ml',
          syringeCount: 10,
          syringeRefills: 2,
          injectionSiteNotes: 'Notes',
          frequency: InjectionFrequency.weekly,
          subtype: InjectionSubtype.subcutaneous,
        ),
      );

      final ivInjection = Medication(
        name: 'IV Injectable',
        dosage: '200mg',
        startDate: DateTime(2023, 6, 15),
        frequency: 1,
        timeOfDay: [DateTime(2023, 6, 15, 9, 0)],
        daysOfWeek: {'Su'},
        currentQuantity: 5,
        refillThreshold: 2,
        medicationType: MedicationType.injection,
        injectionDetails: InjectionDetails(
          drawingNeedleType: '16G',
          drawingNeedleCount: 10,
          drawingNeedleRefills: 2,
          injectingNeedleType: '20G',
          injectingNeedleCount: 8,
          injectingNeedleRefills: 2,
          syringeType: '10ml',
          syringeCount: 10,
          syringeRefills: 2,
          injectionSiteNotes: 'Notes',
          frequency: InjectionFrequency.weekly,
          subtype: InjectionSubtype.intravenous,
        ),
      );

      // Assert - verify subtypes are correctly stored
      expect(imInjection.injectionDetails?.subtype,
          equals(InjectionSubtype.intramuscular));
      expect(scInjection.injectionDetails?.subtype,
          equals(InjectionSubtype.subcutaneous));
      expect(ivInjection.injectionDetails?.subtype,
          equals(InjectionSubtype.intravenous));
    });
  });
}
