//
//  validation_service.dart
//  Centralized validation logic for app-wide use
//
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/core/constants/date_constants.dart';

/// Service providing validation rules and messages for data across the application
class ValidationService {
  // Private constructor to prevent instantiation
  ValidationService._();

  //----------------------------------------------------------------------------
  // MEDICATION VALIDATION
  //----------------------------------------------------------------------------

  /// Validate a medication name
  static ValidationResult validateMedicationName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter a medication name',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate a medication dosage
  static ValidationResult validateMedicationDosage(String? dosage) {
    if (dosage == null || dosage.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter the dosage',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate frequency (times per day)
  static ValidationResult validateFrequency(int frequency) {
    if (frequency < 1 || frequency > 10) {
      return ValidationResult(
        isValid: false,
        message: 'Frequency must be between 1 and 10',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate time of day entries
  static ValidationResult validateTimeOfDay(
      List<DateTime> timeOfDay, int frequency) {
    if (timeOfDay.length != frequency) {
      return ValidationResult(
        isValid: false,
        message: 'Number of times must match frequency',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate days of week selection
  static ValidationResult validateDaysOfWeek(Set<String> daysOfWeek) {
    if (daysOfWeek.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: 'At least one day must be selected',
      );
    }

    if (!daysOfWeek.every((day) => DateConstants.orderedDays.contains(day))) {
      return ValidationResult(
        isValid: false,
        message: 'Invalid day selection',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate medication inventory quantity
  static ValidationResult validateQuantity(int quantity) {
    if (quantity < 0) {
      return ValidationResult(
        isValid: false,
        message: 'Quantity cannot be negative',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate injection details based on medication type
  static ValidationResult validateInjectionDetails(
      MedicationType type, InjectionDetails? details, int frequency) {
    if (type == MedicationType.injection && details == null) {
      return ValidationResult(
        isValid: false,
        message: 'Injection details required for injection type',
      );
    }

    if (type != MedicationType.injection && details != null) {
      return ValidationResult(
        isValid: false,
        message: 'Only injection type should have injection details',
      );
    }

    if (type == MedicationType.injection &&
        details?.frequency == InjectionFrequency.biweekly &&
        frequency != 1) {
      return ValidationResult(
        isValid: false,
        message: 'Biweekly injections must have frequency of 1',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate oral subtype based on medication type
  static ValidationResult validateOralSubtype(
      MedicationType type, OralSubtype? subtype) {
    if (type == MedicationType.oral && subtype == null) {
      return ValidationResult(
        isValid: false,
        message: 'Oral subtype required for oral medications',
      );
    }

    if (type != MedicationType.oral && subtype != null) {
      return ValidationResult(
        isValid: false,
        message: 'Only oral type should have oral subtype',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate topical subtype based on medication type
  static ValidationResult validateTopicalSubtype(
      MedicationType type, TopicalSubtype? subtype) {
    if (type == MedicationType.topical && subtype == null) {
      return ValidationResult(
        isValid: false,
        message: 'Topical subtype required for topical medications',
      );
    }

    if (type != MedicationType.topical && subtype != null) {
      return ValidationResult(
        isValid: false,
        message: 'Only topical type should have topical subtype',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate needle type
  static ValidationResult validateNeedleType(String? needleType) {
    if (needleType == null || needleType.isEmpty) {
      return ValidationResult(
          isValid: false, message: 'Please enter needle type');
    }
    return ValidationResult.valid();
  }

  /// Validate syringe type
  static ValidationResult validateSyringeType(String? syringeType) {
    if (syringeType == null || syringeType.isEmpty) {
      return ValidationResult(
          isValid: false, message: 'Please enter syringe type');
    }
    return ValidationResult.valid();
  }

  /// Validate needle count
  static ValidationResult validateNeedleCount(String? countStr) {
    final count = int.tryParse(countStr ?? '');
    if (count == null) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter a valid number',
      );
    }
    return ValidationResult.valid();
  }

  //----------------------------------------------------------------------------
  // FORM INPUT VALIDATORS - Return string for Flutter form validation
  //----------------------------------------------------------------------------

  /// TextFormField validator for medication name
  static String? nameValidator(String? value) {
    final result = validateMedicationName(value);
    return result.isValid ? null : result.message;
  }

  /// TextFormField validator for medication dosage
  static String? dosageValidator(String? value) {
    final result = validateMedicationDosage(value);
    return result.isValid ? null : result.message;
  }

  /// TextFormField validator for needle type
  static String? needleTypeValidator(String? value) {
    final result = validateNeedleType(value);
    return result.isValid ? null : result.message;
  }

  /// TextFormField validator for syringe type
  static String? syringeTypeValidator(String? value) {
    final result = validateSyringeType(value);
    return result.isValid ? null : result.message;
  }

  /// TextFormField validator for numeric inputs
  static String? numberValidator(String? value) {
    if (value == null || int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}

/// Result of a validation check
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult({
    required this.isValid,
    this.message,
  });

  /// Create a valid result with no message
  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  /// Check if validation passed
  bool get hasError => !isValid;
}
