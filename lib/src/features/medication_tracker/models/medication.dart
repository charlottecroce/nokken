import 'package:uuid/uuid.dart';

enum MedicationType { oral, injection }

enum InjectionFrequency { weekly, biweekly }

class InjectionDetails {
  final String drawingNeedleType;
  final int drawingNeedleCount;
  final int drawingNeedleRefills;
  final String injectingNeedleType;
  final int injectingNeedleCount;
  final int injectingNeedleRefills;
  final String injectionSiteNotes;
  final InjectionFrequency frequency;

  InjectionDetails({
    required this.drawingNeedleType,
    required this.drawingNeedleCount,
    required this.drawingNeedleRefills,
    required this.injectingNeedleType,
    required this.injectingNeedleCount,
    required this.injectingNeedleRefills,
    required this.injectionSiteNotes,
    required this.frequency,
  });

  Map<String, dynamic> toJson() => {
        'drawingNeedleType': drawingNeedleType,
        'drawingNeedleCount': drawingNeedleCount,
        'drawingNeedleRefills': drawingNeedleRefills,
        'injectingNeedleType': injectingNeedleType,
        'injectingNeedleCount': injectingNeedleCount,
        'injectingNeedleRefills': injectingNeedleRefills,
        'injectionSiteNotes': injectionSiteNotes,
        'frequency': frequency.toString(),
      };

  factory InjectionDetails.fromJson(Map<String, dynamic> json) {
    return InjectionDetails(
      drawingNeedleType: json['drawingNeedleType'],
      drawingNeedleCount: json['drawingNeedleCount'],
      drawingNeedleRefills: json['drawingNeedleRefills'],
      injectingNeedleType: json['injectingNeedleType'],
      injectingNeedleCount: json['injectingNeedleCount'],
      injectingNeedleRefills: json['injectingNeedleRefills'],
      injectionSiteNotes: json['injectionSiteNotes'],
      frequency: InjectionFrequency.values.firstWhere(
          (e) => e.toString() == json['frequency'],
          orElse: () => InjectionFrequency.weekly),
    );
  }
}

class MedicationException implements Exception {
  final String message;
  MedicationException(this.message);

  @override
  String toString() => 'MedicationException: $message';
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final DateTime startDate;
  final int frequency;
  final List<DateTime> timeOfDay;
  final Set<String> daysOfWeek;
  final int currentQuantity;
  final int refillThreshold;
  final String? notes;
  final MedicationType medicationType;
  final InjectionDetails? injectionDetails; // null for oral medications

  static const validDays = {'Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'};

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
    this.notes,
  }) : id = id ?? const Uuid().v4() {
    _validate();
  }

  void _validate() {
    if (name.trim().isEmpty) {
      throw MedicationException('Name cannot be empty');
    }
    if (dosage.trim().isEmpty) {
      throw MedicationException('Dosage cannot be empty');
    }
    if (frequency < 1 || frequency > 10) {
      throw MedicationException('Frequency must be between 1 and 10');
    }
    if (timeOfDay.length != frequency) {
      throw MedicationException('Number of times must match frequency');
    }
    if (daysOfWeek.isEmpty) {
      throw MedicationException('At least one day must be selected');
    }
    if (!daysOfWeek.every((day) => validDays.contains(day))) {
      throw MedicationException('Invalid day selection');
    }
    if (currentQuantity < 0) {
      throw MedicationException('Current quantity cannot be negative');
    }
    if (medicationType == MedicationType.injection &&
        injectionDetails == null) {
      throw MedicationException(
          'Injection details required for injection type');
    }
    if (medicationType == MedicationType.oral && injectionDetails != null) {
      throw MedicationException(
          'Oral medication should not have injection details');
    }
    if (medicationType == MedicationType.injection &&
        injectionDetails!.frequency == InjectionFrequency.biweekly &&
        frequency != 1) {
      throw MedicationException('Biweekly injections must have frequency of 1');
    }
  }

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
      if (injectionDetails != null)
        'injectionDetails': injectionDetails!.toJson(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    try {
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
        medicationType: MedicationType.values
            .firstWhere((e) => e.toString() == json['medicationType']),
        injectionDetails: json['injectionDetails'] != null
            ? InjectionDetails.fromJson(json['injectionDetails'])
            : null,
      );
    } catch (e) {
      throw MedicationException('Invalid medication data: $e');
    }
  }

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
    );
  }

  bool needsRefill() => currentQuantity < refillThreshold;
}
