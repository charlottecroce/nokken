// test/core/services/error/validation_result_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/core/services/error/validation_service.dart';

void main() {
  group('ValidationResult', () {
    test('constructor should initialize properties correctly', () {
      // Arrange & Act - create a valid validation result
      final validResult = ValidationResult(isValid: true, message: null);

      // Assert
      expect(validResult.isValid, isTrue);
      expect(validResult.message, isNull);
      expect(validResult.hasError, isFalse);

      // Arrange & Act - create an invalid validation result
      final invalidResult = ValidationResult(
        isValid: false,
        message: 'Error message',
      );

      // Assert
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.message, equals('Error message'));
      expect(invalidResult.hasError, isTrue);
    });

    test('valid factory should create a valid result', () {
      // Act - create a valid result using factory
      final result = ValidationResult.valid();

      // Assert
      expect(result.isValid, isTrue);
      expect(result.message, isNull);
      expect(result.hasError, isFalse);
    });

    test('hasError should return inverse of isValid', () {
      // Arrange
      final validResult = ValidationResult(isValid: true);
      final invalidResult = ValidationResult(isValid: false);

      // Assert
      expect(validResult.hasError, isFalse);
      expect(invalidResult.hasError, isTrue);
    });

    // Integration test with ValidationService
    test(
        'validateMedicationName should return ValidationResult with correct values',
        () {
      // Act - validate a valid name
      final validResult =
          ValidationService.validateMedicationName('Test Medication');

      // Assert
      expect(validResult, isA<ValidationResult>());
      expect(validResult.isValid, isTrue);
      expect(validResult.hasError, isFalse);

      // Act - validate an invalid name
      final invalidResult = ValidationService.validateMedicationName('');

      // Assert
      expect(invalidResult, isA<ValidationResult>());
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.hasError, isTrue);
      expect(invalidResult.message, equals('Please enter a medication name'));
    });

    test('validateDaysOfWeek should validate day sets correctly', () {
      // Arrange
      final validDays = {'M', 'W', 'F'};
      final emptyDays = <String>{};
      final invalidDays = {'M', 'X', 'F'}; // 'X' is not a valid day

      // Act
      final validResult = ValidationService.validateDaysOfWeek(validDays);
      final emptyResult = ValidationService.validateDaysOfWeek(emptyDays);
      final invalidResult = ValidationService.validateDaysOfWeek(invalidDays);

      // Assert
      expect(validResult.isValid, isTrue);
      expect(emptyResult.isValid, isFalse);
      expect(invalidResult.isValid, isFalse);

      expect(emptyResult.message, contains('At least one day'));
      expect(invalidResult.message, contains('Invalid day'));
    });

    test(
        'form validators should convert ValidationResults to strings correctly',
        () {
      // Act & Assert - valid input should return null
      expect(ValidationService.nameValidator('Valid Name'), isNull);

      // Act & Assert - invalid input should return error message
      expect(ValidationService.nameValidator(''), isNotNull);
      expect(ValidationService.nameValidator(''),
          equals('Please enter a medication name'));

      // Act & Assert - number validator
      expect(ValidationService.numberValidator('42'), isNull);
      expect(ValidationService.numberValidator('abc'), isNotNull);
      expect(
          ValidationService.numberValidator('abc'), contains('valid number'));
    });
  });
}
