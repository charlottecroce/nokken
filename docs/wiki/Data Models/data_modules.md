# Data Modules
## Medication Models

The Medication model (`lib/src/features/medication_tracker/models/medication.dart`) represents a user's medication:

```dart
class Medication {
  final String id;
  final String name;
  final String dosage;
  final DateTime startDate;
  final int frequency;           // Times per day
  final List<DateTime> timeOfDay; // Specific times for each dose
  final Set<String> daysOfWeek;
  final int currentQuantity;
  final int refillThreshold;
  final String? notes;
  final MedicationType medicationType;
  final InjectionDetails? injectionDetails; // null for oral medications
  
  // Methods for checking if medication is due on a date
  bool isDueOnDate(DateTime date) {...}
  
  // Methods for checking refill status
  bool needsRefill() => currentQuantity < refillThreshold;
}
```

For injectable medications, the InjectionDetails class provides additional fields:
```dart
class InjectionDetails {
  final String drawingNeedleType;
  final int drawingNeedleCount;
  final int drawingNeedleRefills;
  final String injectingNeedleType;
  final int injectingNeedleCount;
  final int injectingNeedleRefills;
  final String injectionSiteNotes;
  final InjectionFrequency frequency;
}
```

The MedicationDose model represents a specific instance of a medication taken:
```dart
class MedicationDose {
  final String medicationId;
  final DateTime date;
  final String timeSlot;
  
  // Methods for generating unique keys
  String toKey() {...}
  static MedicationDose fromKey(String key) {...}
}
```

## Bloodwork Models
The Bloodwork model (`lib/src/features/bloodwork_tracker/models/bloodwork.dart`) represents a medical appointment or bloodwork record:
```dart
class Bloodwork {
  final String id;
  final DateTime date;
  final AppointmentType appointmentType;
  final List<HormoneReading> hormoneReadings;
  final String? location;
  final String? doctor;
  final String? notes;
}
```
Hormone readings are tracked with the HormoneReading class:
```dart
class HormoneReading {
  final String name;
  final double value;
  final String unit;
  
  // Serialization methods
  Map<String, dynamic> toJson() {...}
  factory HormoneReading.fromJson(Map<String, dynamic> json) {...}
}
```
The application supports three types of appointments:
```dart
enum AppointmentType { bloodwork, appointment, surgery }
```
