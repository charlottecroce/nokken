// test/features/bloodwork_tracker/models/bloodwork_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';

void main() {
  group('Bloodwork Model', () {
    // Test constructor and validation
    test('should create valid bloodwork record', () {
      // Arrange - create a valid bloodwork object
      final bloodwork = Bloodwork(
        date: DateTime(2023, 6, 15),
        appointmentType: AppointmentType.bloodwork,
        hormoneReadings: [
          HormoneReading(name: 'Estrogen', value: 120.5, unit: 'pg/mL'),
          HormoneReading(name: 'Testosterone', value: 30.2, unit: 'ng/dL'),
        ],
        location: 'City Hospital',
        doctor: 'Dr. Smith',
        notes: 'Regular checkup',
      );

      // Assert - verify properties are set correctly
      expect(bloodwork.date, equals(DateTime(2023, 6, 15)));
      expect(bloodwork.appointmentType, equals(AppointmentType.bloodwork));
      expect(bloodwork.hormoneReadings.length, equals(2));
      expect(bloodwork.location, equals('City Hospital'));
      expect(bloodwork.doctor, equals('Dr. Smith'));
      expect(bloodwork.notes, equals('Regular checkup'));
      expect(bloodwork.id, isNotEmpty); // Auto-generated ID should not be empty
    });

    test('should throw exception for negative hormone levels', () {
      // Arrange & Act - try to create bloodwork with negative hormone level
      invalidReading() => Bloodwork(
            date: DateTime(2023, 6, 15),
            appointmentType: AppointmentType.bloodwork,
            hormoneReadings: [
              HormoneReading(name: 'Estrogen', value: -10.0, unit: 'pg/mL'),
            ],
          );

      // Assert - verify exception is thrown
      expect(invalidReading, throwsA(isA<BloodworkException>()));
    });

    test('should allow future dates for appointment types', () {
      // Arrange - future date with no hormone values
      final futureBloodwork = Bloodwork(
        date: DateTime.now().add(const Duration(days: 30)),
        appointmentType: AppointmentType.appointment, // Not bloodwork type
        location: 'City Hospital',
      );

      // Assert - verify this is valid
      expect(
          futureBloodwork.appointmentType, equals(AppointmentType.appointment));
    });

    test(
        'should throw exception for bloodwork type with no hormone readings on past date',
        () {
      // Past date with no hormone readings for bloodwork type should throw exception
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      // Arrange & Act - try to create invalid bloodwork
      invalidBloodwork() => Bloodwork(
            date: pastDate,
            appointmentType: AppointmentType.bloodwork,
            hormoneReadings: [], // No readings
          );

      // Assert - verify exception is thrown
      expect(invalidBloodwork, throwsA(isA<BloodworkException>()));
    });

    // Test JSON conversion
    test('should convert to and from JSON correctly', () {
      // Arrange - create a bloodwork object
      final original = Bloodwork(
        id: 'test-id-123',
        date: DateTime(2023, 6, 15),
        appointmentType: AppointmentType.bloodwork,
        hormoneReadings: [
          HormoneReading(name: 'Estrogen', value: 120.5, unit: 'pg/mL'),
        ],
        location: 'City Hospital',
      );

      // Act - convert to JSON and back
      final json = original.toJson();
      final restored = Bloodwork.fromJson(json);

      // Assert - verify properties match
      expect(restored.id, equals(original.id));
      expect(restored.date.year, equals(original.date.year));
      expect(restored.date.month, equals(original.date.month));
      expect(restored.date.day, equals(original.date.day));
      expect(restored.appointmentType, equals(original.appointmentType));
      expect(restored.hormoneReadings.length,
          equals(original.hormoneReadings.length));
      expect(restored.hormoneReadings[0].name,
          equals(original.hormoneReadings[0].name));
      expect(restored.hormoneReadings[0].value,
          equals(original.hormoneReadings[0].value));
      expect(restored.location, equals(original.location));
    });

    // Test legacy getters
    test(
        'should provide estrogen and testosterone values through legacy getters',
        () {
      // Arrange - create a bloodwork with specific hormone readings
      final bloodwork = Bloodwork(
        date: DateTime(2023, 6, 15),
        appointmentType: AppointmentType.bloodwork,
        hormoneReadings: [
          HormoneReading(name: 'Estrogen', value: 120.5, unit: 'pg/mL'),
          HormoneReading(name: 'Testosterone', value: 30.2, unit: 'ng/dL'),
          HormoneReading(name: 'Progesterone', value: 0.5, unit: 'ng/mL'),
        ],
      );

      // Assert - verify legacy getters work correctly
      expect(bloodwork.estrogen, equals(120.5));
      expect(bloodwork.testosterone, equals(30.2));
    });

    // Test HormoneReading
    test('HormoneReading should convert to and from JSON correctly', () {
      // Arrange - create a hormone reading
      final reading = HormoneReading(
        name: 'Estrogen',
        value: 120.5,
        unit: 'pg/mL',
      );

      // Act - convert to JSON and back
      final json = reading.toJson();
      final restored = HormoneReading.fromJson(json);

      // Assert - verify properties match
      expect(restored.name, equals(reading.name));
      expect(restored.value, equals(reading.value));
      expect(restored.unit, equals(reading.unit));
    });

    // Test copyWith
    test('copyWith should create a new instance with updated values', () {
      // Arrange - create a bloodwork object
      final original = Bloodwork(
        date: DateTime(2023, 6, 15),
        appointmentType: AppointmentType.bloodwork,
        hormoneReadings: [
          HormoneReading(name: 'Estrogen', value: 120.5, unit: 'pg/mL'),
        ],
      );

      // Act - create a copy with updated values
      final updated = original.copyWith(
        date: DateTime(2023, 7, 20),
        appointmentType: AppointmentType.appointment,
        notes: 'Updated notes',
      );

      // Assert - verify original is unchanged and copy has updates
      expect(original.date, equals(DateTime(2023, 6, 15)));
      expect(original.appointmentType, equals(AppointmentType.bloodwork));
      expect(original.notes, isNull);

      expect(updated.date, equals(DateTime(2023, 7, 20)));
      expect(updated.appointmentType, equals(AppointmentType.appointment));
      expect(updated.notes, equals('Updated notes'));
      expect(updated.id, equals(original.id)); // ID should remain the same
      expect(updated.hormoneReadings,
          equals(original.hormoneReadings)); // Readings unchanged
    });
  });

  // Test HormoneTypes utility class
  group('HormoneTypes', () {
    test('should provide default units for hormone types', () {
      // Act & Assert - check a few default units
      expect(HormoneTypes.getDefaultUnit('Estrogen'), equals('pg/mL'));
      expect(HormoneTypes.getDefaultUnit('Testosterone'), equals('ng/dL'));
      expect(HormoneTypes.getDefaultUnit('Progesterone'), equals('ng/mL'));
      expect(HormoneTypes.getDefaultUnit('Unknown'), equals(''));
    });

    test('should provide list of available hormone types', () {
      // Act - get the list of hormone types
      final types = HormoneTypes.getHormoneTypes();

      // Assert - verify the list contains expected types
      expect(types, contains('Estrogen'));
      expect(types, contains('Testosterone'));
      expect(types, contains('Prolactin'));
      expect(
          types.length, greaterThanOrEqualTo(5)); // Should have several types
    });
  });
}
