//
//  medication.dart
//  Core model for medication data
//
import 'package:uuid/uuid.dart';
import 'package:nokken/src/core/constants/date_constants.dart';
import 'package:nokken/src/core/services/error/validation_service.dart';

/// Types of medications supported
enum MedicationType { oral, injection, topical, patch }

/// Subtypes for oral medications
enum OralSubtype { tablets, capsules, drops }

/// Subtypes for topical medications
enum TopicalSubtype { gel, cream, spray }

/// Subtypes for injection medications
enum InjectionSubtype { intravenous, intramuscular, subcutaneous }

/// Frequency options for injectable medications
enum InjectionFrequency { weekly, biweekly }

/// Details specific to injectable medications
class InjectionDetails {
  final String drawingNeedleType;
  final int drawingNeedleCount;
  final int drawingNeedleRefills;
  final String injectingNeedleType;
  final int injectingNeedleCount;
  final int injectingNeedleRefills;
  final String syringeType;
  final int syringeCount;
  final int syringeRefills;
  final String injectionSiteNotes;
  final InjectionFrequency frequency;
  final InjectionSubtype subtype;

  InjectionDetails({
    required this.drawingNeedleType,
    required this.drawingNeedleCount,
    required this.drawingNeedleRefills,
    required this.injectingNeedleType,
    required this.injectingNeedleCount,
    required this.injectingNeedleRefills,
    required this.syringeType,
    required this.syringeCount,
    required this.syringeRefills,
    required this.injectionSiteNotes,
    required this.frequency,
    required this.subtype,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() => {
        'drawingNeedleType': drawingNeedleType,
        'drawingNeedleCount': drawingNeedleCount,
        'drawingNeedleRefills': drawingNeedleRefills,
        'injectingNeedleType': injectingNeedleType,
        'injectingNeedleCount': injectingNeedleCount,
        'injectingNeedleRefills': injectingNeedleRefills,
        'syringeType': syringeType,
        'syringeCount': syringeCount,
        'syringeRefills': syringeRefills,
        'injectionSiteNotes': injectionSiteNotes,
        'frequency': frequency.toString(),
        'subtype': subtype.toString(),
      };

  /// Create InjectionDetails from JSON (database record)
  factory InjectionDetails.fromJson(Map<String, dynamic> json) {
    return InjectionDetails(
      drawingNeedleType: json['drawingNeedleType'],
      drawingNeedleCount: json['drawingNeedleCount'],
      drawingNeedleRefills: json['drawingNeedleRefills'],
      injectingNeedleType: json['injectingNeedleType'],
      injectingNeedleCount: json['injectingNeedleCount'],
      injectingNeedleRefills: json['injectingNeedleRefills'],
      syringeType: json['syringeType'] ?? '',
      syringeCount: json['syringeCount'] ?? 0,
      syringeRefills: json['syringeRefills'] ?? 0,
      injectionSiteNotes: json['injectionSiteNotes'],
      frequency: InjectionFrequency.values.firstWhere(
          (e) => e.toString() == json['frequency'],
          orElse: () => InjectionFrequency.weekly),
      subtype: InjectionSubtype.values.firstWhere(
          (e) => e.toString() == json['subtype'],
          orElse: () => InjectionSubtype.intramuscular),
    );
  }
}

/// Custom exception for medication-related errors
class MedicationException implements Exception {
  final String message;
  MedicationException(this.message);

  @override
  String toString() => 'MedicationException: $message';
}

/// Primary model for medication data
class Medication {
  final String id;
  final String name;
  final String dosage;
  final DateTime startDate;
  final int frequency; // Times per day
  final List<DateTime> timeOfDay; // Specific times for each dose
  final Set<String> daysOfWeek;
  final int currentQuantity;
  final int refillThreshold;
  final String? notes;
  final MedicationType medicationType;
  final InjectionDetails?
      injectionDetails; // null for non-injection medications
  final OralSubtype? oralSubtype; // null for non-oral medications
  final TopicalSubtype? topicalSubtype; // null for non-topical medications
  final String? doctor; // Optional doctor name
  final String? pharmacy; // Optional pharmacy name

  /// Constructor with validation
  Medication({
    String? id,
    required this.name,
    required this.dosage,
    required this.startDate,
    required this.frequency,
    required this.timeOfDay,
    required this.daysOfWeek,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.medicationType,
    this.injectionDetails,
    this.oralSubtype,
    this.topicalSubtype,
    this.notes,
    this.doctor,
    this.pharmacy,
  }) : id = id ?? const Uuid().v4() {
    _validate();
  }

  /// Validates medication fields
  void _validate() {
    final nameResult = ValidationService.validateMedicationName(name);
    if (nameResult.hasError) {
      throw MedicationException(nameResult.message!);
    }

    final dosageResult = ValidationService.validateMedicationDosage(dosage);
    if (dosageResult.hasError) {
      throw MedicationException(dosageResult.message!);
    }

    final frequencyResult = ValidationService.validateFrequency(frequency);
    if (frequencyResult.hasError) {
      throw MedicationException(frequencyResult.message!);
    }

    final timeResult =
        ValidationService.validateTimeOfDay(timeOfDay, frequency);
    if (timeResult.hasError) {
      throw MedicationException(timeResult.message!);
    }

    final daysResult = ValidationService.validateDaysOfWeek(daysOfWeek);
    if (daysResult.hasError) {
      throw MedicationException(daysResult.message!);
    }

    final quantityResult = ValidationService.validateQuantity(currentQuantity);
    if (quantityResult.hasError) {
      throw MedicationException(quantityResult.message!);
    }

    final injectionResult = ValidationService.validateInjectionDetails(
        medicationType, injectionDetails, frequency);
    if (injectionResult.hasError) {
      throw MedicationException(injectionResult.message!);
    }

    // Validate subtypes match medication type
    if (medicationType == MedicationType.oral && oralSubtype == null) {
      throw MedicationException('Oral subtype required for oral medications');
    }

    if (medicationType == MedicationType.topical && topicalSubtype == null) {
      throw MedicationException(
          'Topical subtype required for topical medications');
    }

    if (medicationType != MedicationType.oral && oralSubtype != null) {
      throw MedicationException(
          'Oral subtype should only be set for oral medications');
    }

    if (medicationType != MedicationType.topical && topicalSubtype != null) {
      throw MedicationException(
          'Topical subtype should only be set for topical medications');
    }
  }

  /// Convert to JSON format for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.trim(),
      'dosage': dosage.trim(),
      'startDate': startDate.toIso8601String(),
      'frequency': frequency,
      'timeOfDay': timeOfDay.map((t) => t.toIso8601String()).toList(),
      'daysOfWeek': daysOfWeek.toList(),
      'currentQuantity': currentQuantity,
      'refillThreshold': refillThreshold,
      'notes': notes?.trim(),
      'medicationType': medicationType.toString(),
      'doctor': doctor?.trim(),
      'pharmacy': pharmacy?.trim(),
      'oralSubtype': oralSubtype?.toString(),
      'topicalSubtype': topicalSubtype?.toString(),
      if (injectionDetails != null)
        'injectionDetails': injectionDetails!.toJson(),
    };
  }

  /// Create a Medication instance from JSON (database record)
  factory Medication.fromJson(Map<String, dynamic> json) {
    try {
      // Handle medication type
      final medicationType = MedicationType.values.firstWhere(
        (e) => e.toString() == json['medicationType'],
        orElse: () => MedicationType.oral,
      );

      // Handle oral subtype if present
      OralSubtype? oralSubtype;
      if (json['oralSubtype'] != null) {
        try {
          oralSubtype = OralSubtype.values.firstWhere(
            (e) => e.toString() == json['oralSubtype'],
          );
        } catch (_) {
          // If parsing fails, default to tablets
          oralSubtype = OralSubtype.tablets;
        }
      }

      // Handle topical subtype if present
      TopicalSubtype? topicalSubtype;
      if (json['topicalSubtype'] != null) {
        try {
          topicalSubtype = TopicalSubtype.values.firstWhere(
            (e) => e.toString() == json['topicalSubtype'],
          );
        } catch (_) {
          // If parsing fails, default to gel
          topicalSubtype = TopicalSubtype.gel;
        }
      }

      return Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        startDate: DateTime.parse(json['startDate']),
        frequency: json['frequency'] as int,
        timeOfDay: (json['timeOfDay'] as List)
            .map((t) => DateTime.parse(t as String))
            .toList(),
        daysOfWeek: Set<String>.from(json['daysOfWeek'] as List),
        currentQuantity: json['currentQuantity'] as int,
        refillThreshold: json['refillThreshold'] as int,
        notes: json['notes'] as String?,
        medicationType: medicationType,
        doctor: json['doctor'] as String?,
        pharmacy: json['pharmacy'] as String?,
        oralSubtype: oralSubtype,
        topicalSubtype: topicalSubtype,
        injectionDetails: json['injectionDetails'] != null
            ? InjectionDetails.fromJson(json['injectionDetails'])
            : null,
      );
    } catch (e) {
      throw MedicationException('Invalid medication data: $e');
    }
  }

  /// Create a copy of this medication with updated fields
  Medication copyWith({
    String? name,
    String? dosage,
    int? frequency,
    DateTime? startDate,
    List<DateTime>? timeOfDay,
    Set<String>? daysOfWeek,
    int? currentQuantity,
    int? refillThreshold,
    String? notes,
    MedicationType? medicationType,
    InjectionDetails? injectionDetails,
    OralSubtype? oralSubtype,
    TopicalSubtype? topicalSubtype,
    String? doctor,
    String? pharmacy,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      notes: notes ?? this.notes,
      medicationType: medicationType ?? this.medicationType,
      injectionDetails: injectionDetails ?? this.injectionDetails,
      oralSubtype: oralSubtype ?? this.oralSubtype,
      topicalSubtype: topicalSubtype ?? this.topicalSubtype,
      doctor: doctor ?? this.doctor,
      pharmacy: pharmacy ?? this.pharmacy,
    );
  }

  /// Check if this medication is due on the specified date
  bool isDueOnDate(DateTime date) {
    // Normalize dates to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final startDate =
        DateTime(this.startDate.year, this.startDate.month, this.startDate.day);

    // Basic date validation - not scheduled before start date
    if (normalizedDate.isBefore(startDate)) {
      return false;
    }

    // Check day of week
    final dayAbbr = DateConstants.dayMap[date.weekday] ?? '';
    if (!daysOfWeek.contains(dayAbbr)) {
      return false;
    }

    // Handle biweekly injections
    if (medicationType == MedicationType.injection &&
        injectionDetails?.frequency == InjectionFrequency.biweekly) {
      // Calculate weeks since start
      final daysSince = normalizedDate.difference(startDate).inDays;
      final weeksSince = daysSince ~/ 7;

      // Is this an "on" week or "off" week?
      return weeksSince % 2 == 0;
    }

    return true;
  }

  /// Check if medication needs to be refilled based on current quantity and threshold
  bool needsRefill() => currentQuantity < refillThreshold;
}
