// test/core/services/database_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/core/services/database/database_service.dart';

void main() {
  group('DatabaseService', () {
    // Simple test that always passes
    test('should initialize without errors', () {
      // The test will instantiate the DatabaseService but won't actually
      // use a real database connection during testing
      expect(() => DatabaseService(), returnsNormally);
    });

    test('TakenMedication model converts to and from map correctly', () {
      // Create a test model
      final testModel = TakenMedication(
        medicationId: 'test-id',
        date: DateTime(2023, 1, 15),
        timeSlot: '8:00 AM',
        taken: true,
      );

      // Convert to map
      final map = testModel.toMap();

      // Convert back to model
      final restoredModel = TakenMedication.fromMap(map);

      // Verify conversion was successful
      expect(restoredModel.medicationId, equals('test-id'));
      expect(restoredModel.taken, isTrue);
      expect(restoredModel.timeSlot, equals('8:00 AM'));
    });

    test('uniqueKey is generated correctly for TakenMedication', () {
      // Arrange
      final medicationId = 'med-123';
      final date = DateTime(2023, 1, 15);
      final timeSlot = '8:00 AM';

      // Act
      final takenMed = TakenMedication(
        medicationId: medicationId,
        date: date,
        timeSlot: timeSlot,
        taken: true,
      );

      // Assert
      expect(takenMed.uniqueKey, contains(medicationId));
      expect(takenMed.uniqueKey, contains(timeSlot));
      expect(takenMed.uniqueKey, contains('2023-01-15'));
    });
  });
}
