//
//  bloodwork.dart
//  Model for bloodwork lab results
//
import 'package:uuid/uuid.dart';

/// Custom exception for bloodwork-related errors
class BloodworkException implements Exception {
  final String message;
  BloodworkException(this.message);

  @override
  String toString() => 'BloodworkException: $message';
}

/// Types of appointments supported by the bloodwork tracker
enum AppointmentType { bloodwork, appointment, surgery }

/// Represents a single hormone reading with name, value and unit
class HormoneReading {
  final String name;
  final double value;
  final String unit;

  HormoneReading({
    required this.name,
    required this.value,
    required this.unit,
  });

  /// Convert to JSON format for database storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
    };
  }

  /// Create a HormoneReading from JSON
  factory HormoneReading.fromJson(Map<String, dynamic> json) {
    return HormoneReading(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }

  /// Create a copy with updated fields
  HormoneReading copyWith({
    String? name,
    double? value,
    String? unit,
  }) {
    return HormoneReading(
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}

/// Predefined hormone types with their default units
class HormoneTypes {
  static const Map<String, String> defaultUnits = {
    'Estrogen': 'pg/mL',
    'Testosterone': 'ng/dL',
    'Progesterone': 'ng/mL',
    'FSH': 'mIU/mL',
    'LH': 'mIU/mL',
    'Prolactin': 'ng/mL',
    'DHEA-S': 'μg/dL',
    'Cortisol': 'μg/dL',
    'TSH': 'μIU/mL',
    'Free T4': 'ng/dL',
  };

  /// Get the default unit for a hormone type
  static String getDefaultUnit(String hormoneName) {
    return defaultUnits[hormoneName] ?? '';
  }

  /// Get list of available hormone types
  static List<String> getHormoneTypes() {
    return defaultUnits.keys.toList();
  }
}

/// Primary model for bloodwork lab test data
class Bloodwork {
  final String id;
  final DateTime date;
  final AppointmentType appointmentType;
  final List<HormoneReading> hormoneReadings;
  final String? location;
  final String? doctor;
  final String? notes;

  /// Constructor with validation
  Bloodwork({
    String? id,
    required this.date,
    this.appointmentType = AppointmentType.bloodwork,
    List<HormoneReading>? hormoneReadings,
    this.location,
    this.doctor,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        hormoneReadings = hormoneReadings ?? [] {
    _validate();
  }

  /// For backward compatibility - get estrogen value if present
  double? get estrogen {
    final reading = hormoneReadings
        .where((reading) => reading.name == 'Estrogen')
        .firstOrNull;
    return reading?.value;
  }

  /// For backward compatibility - get testosterone value if present
  double? get testosterone {
    final reading = hormoneReadings
        .where((reading) => reading.name == 'Testosterone')
        .firstOrNull;
    return reading?.value;
  }

  /// Validates bloodwork fields
  void _validate() {
    // Validate hormone readings
    for (final reading in hormoneReadings) {
      if (reading.value < 0) {
        throw BloodworkException('${reading.name} level cannot be negative');
      }
    }

    // For past or present dates with bloodwork type, require at least one hormone level
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (!recordDate.isAfter(today) &&
        appointmentType == AppointmentType.bloodwork &&
        hormoneReadings.isEmpty) {
      throw BloodworkException(
          'At least one hormone level must be provided for past or present bloodwork dates');
    }
  }

  /// Convert to JSON format for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'appointmentType': appointmentType.toString(),
      'hormoneReadings':
          hormoneReadings.map((reading) => reading.toJson()).toList(),
      // For backward compatibility
      'estrogen': estrogen,
      'testosterone': testosterone,
      'location': location?.trim(),
      'doctor': doctor?.trim(),
      'notes': notes?.trim(),
    };
  }

  /// Create a Bloodwork instance from JSON (database record)
  factory Bloodwork.fromJson(Map<String, dynamic> json) {
    try {
      // Parse appointment type from string
      AppointmentType parsedType;
      try {
        parsedType = AppointmentType.values.firstWhere(
            (e) => e.toString() == json['appointmentType'],
            orElse: () => AppointmentType.bloodwork);
      } catch (_) {
        // For backward compatibility with old records without appointmentType
        parsedType = AppointmentType.bloodwork;
      }

      // Handle the transition between old and new formats
      List<HormoneReading> readings = [];

      // First try to parse new format with hormoneReadings list
      if (json['hormoneReadings'] != null) {
        readings = (json['hormoneReadings'] as List)
            .map((reading) => HormoneReading.fromJson(reading))
            .toList();
      } else {
        // For backward compatibility with old format
        if (json['estrogen'] != null) {
          readings.add(HormoneReading(
            name: 'Estrogen',
            value: (json['estrogen'] as num).toDouble(),
            unit: 'pg/mL',
          ));
        }
        if (json['testosterone'] != null) {
          readings.add(HormoneReading(
            name: 'Testosterone',
            value: (json['testosterone'] as num).toDouble(),
            unit: 'ng/dL',
          ));
        }
      }

      return Bloodwork(
        id: json['id'] as String,
        date: DateTime.parse(json['date']),
        appointmentType: parsedType,
        hormoneReadings: readings,
        location: json['location'] as String?,
        doctor: json['doctor'] as String?,
        notes: json['notes'] as String?,
      );
    } catch (e) {
      throw BloodworkException('Invalid bloodwork data: $e');
    }
  }

  /// Create a copy of this bloodwork with updated fields
  Bloodwork copyWith({
    DateTime? date,
    AppointmentType? appointmentType,
    List<HormoneReading>? hormoneReadings,
    String? location,
    String? doctor,
    String? notes,
  }) {
    return Bloodwork(
      id: id,
      date: date ?? this.date,
      appointmentType: appointmentType ?? this.appointmentType,
      hormoneReadings: hormoneReadings ?? this.hormoneReadings,
      location: location ?? this.location,
      doctor: doctor ?? this.doctor,
      notes: notes ?? this.notes,
    );
  }
}
