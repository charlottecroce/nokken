# Core Services
## Database Service
Nokken uses SQLite for local data storage with the sqflite and sqflite_common_ffi packages. The database supports the following entity types:
- Medications (with specific fields for oral vs. injection medications)
- Taken Medications (tracking medication adherence)
- Bloodwork Records (with support for various appointment types)

The DatabaseService class (`lib/src/core/services/database/database_service.dart`) provides a comprehensive API for working with the database:
```dart
class DatabaseService {
  // Database initialization
  Future<Database> get database async {...}
  Future<Database> _initDatabase() async {...}
  Future<void> _createDatabase(Database db) async {...}
  
  // Medication operations
  Future<void> insertMedication(Medication medication) async {...}
  Future<void> updateMedication(Medication medication) async {...}
  Future<void> deleteMedication(String id) async {...}
  Future<List<Medication>> getAllMedications() async {...}
  
  // Medication adherence operations
  Future<void> setMedicationTaken(...) async {...}
  Future<Set<String>> getTakenMedicationsForDate(DateTime date) async {...}
  
  // Bloodwork operations
  Future<void> insertBloodwork(Bloodwork bloodwork) async {...}
  Future<void> updateBloodwork(Bloodwork bloodwork) async {...}
  Future<void> deleteBloodwork(String id) async {...}
  Future<List<Bloodwork>> getAllBloodwork() async {...}
  Future<Bloodwork?> getBloodworkById(String id) async {...}
}
```

## Notification Service
The NotificationService (`lib/src/core/services/notifications/notification_service.dart`) handles push notifications for medication reminders and refill alerts using the `flutter_local_notifications` package

The service is platform-aware and will only attempt to initialize notifications on mobile platforms (iOS and Android).

## Validation Service
The ValidationService (`lib/src/core/services/error/validation_service.dart`) provides centralized validation logic for form inputs:
```dart
class ValidationService {
  // Medication validation
  static ValidationResult validateMedicationName(String? name) {...}
  static ValidationResult validateMedicationDosage(String? dosage) {...}
  static ValidationResult validateFrequency(int frequency) {...}
  static ValidationResult validateTimeOfDay(List<DateTime> timeOfDay, int frequency) {...}
  static ValidationResult validateDaysOfWeek(Set<String> daysOfWeek) {...}
  
  // Form validators for Flutter TextFormField
  static String? nameValidator(String? value) {...}
  static String? dosageValidator(String? value) {...}
  static String? needleTypeValidator(String? value) {...}
  static String? numberValidator(String? value) {...}
}
```
This service ensures consistent validation throughout the app and provides error messages when data doesn't meet requirements.

