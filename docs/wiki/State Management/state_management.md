# State Management
Nokken uses Riverpod for state management, providing a clean and testable approach to handling application state.

## Providers
The main state providers are organized by feature:

### Medication Providers:
```dart
// Main state providers
final medicationStateProvider = StateNotifierProvider<MedicationNotifier, MedicationState>
final medicationTakenProvider = StateNotifierProvider<MedicationTakenNotifier, Set<String>>

// Derived providers
final medicationsProvider = Provider<List<Medication>>
final medicationsLoadingProvider = Provider<bool>
final medicationsErrorProvider = Provider<String?>
final medicationsByNeedRefillProvider = Provider<List<Medication>>
final sortedMedicationsProvider = Provider<List<Medication>>
final groupedMedicationTypeProvider = Provider<Map<String, List<Medication>>>
```

### Bloodwork Providers
```dart
// Main state providers
final bloodworkStateProvider = StateNotifierProvider<BloodworkNotifier, BloodworkState>

// Derived providers
final bloodworkRecordsProvider = Provider<List<Bloodwork>>
final bloodworkLoadingProvider = Provider<bool>
final bloodworkErrorProvider = Provider<String?>
final sortedBloodworkProvider = Provider<List<Bloodwork>>
final bloodworkTypeRecordsProvider = Provider<List<Bloodwork>>
final bloodworkDatesProvider = Provider<Set<DateTime>>
final groupedBloodworkProvider = Provider<Map<String, List<Bloodwork>>>
final hormoneTypesProvider = Provider<List<String>>
final hormoneRecordsProvider = Provider.family<List<MapEntry<DateTime, double>>, String>
final latestHormoneValueProvider = Provider.family<double?, String>
```

### Scheduler Providers
```dart
final selectedDateProvider = StateProvider<DateTime>
final slideDirectionProvider = StateProvider<bool>
final bloodworkForSelectedDateProvider = Provider.family<List<Bloodwork>, DateTime>
final uniqueMedicationDosesProvider = Provider.family<List<(MedicationDose, int, Medication)>, DateTime>
final isUniqueDoseTakenProvider = Provider.family<bool, (MedicationDose, int)>
```

### Theme Providers
```dart
final themeProvider = StateProvider<ThemeMode>
```


## State Notifiers
State changes are managed through notifier classes:

### MedicationNotifier:
```dart
class MedicationNotifier extends StateNotifier<MedicationState> {
  // Notifier methods
  Future<void> loadMedications() async {...}
  Future<void> addMedication(Medication medication) async {...}
  Future<void> updateMedication(Medication medication) async {...}
  Future<void> updateMedicationQuantity(Medication medication, bool taken) async {...}
  Future<void> deleteMedication(String id) async {...}
}
```

### MedicationTakenNotifier:
```dart
class MedicationTakenNotifier extends StateNotifier<Set<String>> {
  // Notifier methods
  Future<void> loadTakenMedicationsForDate(DateTime date) async {...}
  Future<void> setMedicationTaken(MedicationDose dose, bool taken, {String? customKey}) async {...}
  Future<void> clearOldData(int olderThanDays) async {...}
}
```

### BloodworkNotifier:
```dart
class BloodworkNotifier extends StateNotifier<BloodworkState> {
  // Notifier methods
  Future<void> loadBloodwork() async {...}
  Future<void> addBloodwork(Bloodwork bloodwork) async {...}
  Future<void> updateBloodwork(Bloodwork bloodwork) async {...}
  Future<void> deleteBloodwork(String id) async {...}
}
```
