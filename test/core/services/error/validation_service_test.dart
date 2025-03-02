// test/core/services/validation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/core/services/error/validation_service.dart';

void main() {
  group('ValidationService', () {
    group('validateMedicationName', () {
      test('should return valid for non-empty names', () {
        final result = ValidationService.validateMedicationName('Estradiol');
        expect(result.isValid, true);
        expect(result.message, null);
      });

      test('should return invalid for empty names', () {
        final result = ValidationService.validateMedicationName('');
        expect(result.isValid, false);
        expect(result.message, 'Please enter a medication name');
      });

      test('should return invalid for null names', () {
        final result = ValidationService.validateMedicationName(null);
        expect(result.isValid, false);
        expect(result.message, 'Please enter a medication name');
      });
    });

    group('Form validators', () {
      test('nameValidator should return null for valid names', () {
        final result = ValidationService.nameValidator('Estradiol');
        expect(result, null);
      });

      test('nameValidator should return error message for invalid names', () {
        final result = ValidationService.nameValidator('');
        expect(result, isNotEmpty);
      });

      test('numberValidator should return null for valid numbers', () {
        final result = ValidationService.numberValidator('42');
        expect(result, null);
      });

      test('numberValidator should return error message for invalid numbers',
          () {
        final result = ValidationService.numberValidator('abc');
        expect(result, isNotEmpty);
      });
    });
  });
}
