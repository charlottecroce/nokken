# Core Services
Nokken's architecture is built around several core services that provide foundational functionality to the application. These services follow a singleton pattern for efficient resource usage and are designed with clear separation of concerns.

## Database Service
The `DatabaseService` is the heart of Nokken's data persistence layer, providing a structured interface to the SQLite database. This service follows the repository pattern to abstract database operations from the rest of the application. Nokken uses SQLite for local data storage with the `sqflite` and `sqflite_common_ffi` packages.

### Database Schema and Versioning
The database uses version numbers to track schema changes. This enables smooth updates as the application evolves. When the database is first opened or when upgrading to a new version, appropriate schema creation or migration methods are called


### Entity Tables
The database consists of the following tables:
- `medications`: Stores medication information with specialized fields for injection
- `taken_medications`: Records which medications have been taken
- `bloodwork`: Stores lab results and appointment information

### Data Operations
The service provides specialized methods for each entity type:
#### Medication Operations
```dart
// Example of how to add a new medication
Future<void> addMedication() async {
  final medication = Medication(
    name: "Estradiol",
    dosage: "2mg",
    startDate: DateTime.now(),
    frequency: 2,
    timeOfDay: [DateTime(2023, 1, 1, 8, 0), DateTime(2023, 1, 1, 20, 0)],
    daysOfWeek: {"M", "W", "F"},
    currentQuantity: 30,
    refillThreshold: 5,
    medicationType: MedicationType.oral
  );
  
  try {
    final dbService = DatabaseService();
    await dbService.insertMedication(medication);
    // Medication added successfully
  } catch (e) {
    // Handle error (show error message, log, etc.)
  }
}
```
#### Medication Adherence Tracking
The system uses a unique key approach to track medication doses:
```dart
// Example: Marking a medication as taken
Future<void> markMedicationAsTaken(String medicationId, DateTime date, String timeSlot) async {
  try {
    final dbService = DatabaseService();
    
    // The custom key allows tracking multiple doses of the same medication at the same time slot
    final customKey = '$medicationId-${date.toIso8601String()}-$timeSlot-0';
    
    await dbService.setMedicationTakenWithCustomKey(
      medicationId,
      date,
      timeSlot,
      true,  // taken
      customKey
    );
    
    // Medication marked as taken
  } catch (e) {
    // Handle error (show error message, log, etc.)
  }
}
```
#### Bloodwork and Appointments
```dart
// Example: Adding a bloodwork appointment with hormone readings
Future<void> addBloodworkRecord() async {
  final hormoneReadings = [
    HormoneReading(name: "Estrogen", value: 165.3, unit: "pg/mL"),
    HormoneReading(name: "Testosterone", value: 12.5, unit: "ng/dL")
  ];
  
  final bloodwork = Bloodwork(
    date: DateTime.now(),
    appointmentType: AppointmentType.bloodwork,
    hormoneReadings: hormoneReadings,
    location: "City Medical Lab",
    doctor: "Dr. Smith"
  );
  
  try {
    final dbService = DatabaseService();
    await dbService.insertBloodwork(bloodwork);
    // Bloodwork record added successfully
  } catch (e) {
    // Handle error (show error message, log, etc.)
  }
}
```

### Error Handling
The service uses a custom `DatabaseException` class to provide detailed error information:
```dart
class DatabaseException implements Exception {
  final String message;
  final dynamic error;
  DatabaseException(this.message, [this.error]);

  @override
  String toString() =>
      'DatabaseException: $message${error != null ? ' ($error)' : ''}';
}
```


### Best Practices
- Always use try/catch blocks to handle potential errors
- Use transactions for operations that modify multiple records
- Avoid making database calls on the UI thread for operations that might take time
- Let the service handle data conversion between Dart objects and database maps
- Use the provided methods rather than direct SQL queries for type safety


## Notification Service
The NotificationService (`lib/src/core/services/notifications/notification_service.dart`) handles push notifications for medication reminders and refill alerts using the `flutter_local_notifications` package. The service is platform-aware and will only attempt to initialize notifications on mobile platforms (iOS and Android).

### Best Practices
- Always initialize the service before scheduling notifications
- Handle permission denial gracefully and provide alternative reminders
- Always cancel existing notifications before scheduling new ones
- Test notifications on real devices, as emulators may not display them properly
- Remember that desktop platforms won't show notifications; we could possibly create UI alternatives

## Validation Service
The ValidationService (`lib/src/core/services/error/validation_service.dart`) provides centralized validation logic for form inputs. This service ensures consistent validation throughout the app and provides error messages when data doesn't meet requirements.

### Validation Structure
Each validation method returns a `ValidationResult` that includes both a success status and an optional error message:

```dart
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult({
    required this.isValid,
    this.message,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
  bool get hasError => !isValid;
}
```

### Integration with Flutter Forms
For direct use with Flutter's `TextFormField` widgets, the service provides validator functions that return the expected string format:

```dart
// Text form field validator that can be used directly in forms
static String? nameValidator(String? value) {
  final result = validateMedicationName(value);
  return result.isValid ? null : result.message;
}

// Usage in a form:
TextFormField(
  decoration: InputDecoration(labelText: 'Medication Name'),
  validator: ValidationService.nameValidator,
  // Other properties...
)
```

### Usage Example
The validation service is typically used in model constructors to ensure data integrity:
```dart
// In the Medication class constructor
Medication({
  String? id,
  required this.name,
  required this.dosage,
  // Other fields...
}) : id = id ?? const Uuid().v4() {
  // Validate all fields
  _validate();
}

// Validation method
void _validate() {
  final nameResult = ValidationService.validateMedicationName(name);
  if (nameResult.hasError) {
    throw MedicationException(nameResult.message!);
  }

  final dosageResult = ValidationService.validateMedicationDosage(dosage);
  if (dosageResult.hasError) {
    throw MedicationException(dosageResult.message!);
  }
  
  // More validations...
}
```
### Best Practices
- Always validate input data before saving to the database
- Compose validations for complex rules rather than creating monolithic validators
- Use the form field validators for `TextFormField` components
- Add custom validators by following the `ValidationResult` pattern
- Consider validation contextually - some rules may vary based on other data

