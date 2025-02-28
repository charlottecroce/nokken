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

/// Primary model for bloodwork lab test data
class Bloodwork {
  final String id;
  final DateTime date;
  final AppointmentType appointmentType;
  final double? estrogen; // pg/mL
  final double? testosterone; // ng/dL
  final String? location;
  final String? doctor;
  final String? notes;

  /// Constructor with validation
  Bloodwork({
    String? id,
    required this.date,
    this.appointmentType = AppointmentType.bloodwork,
    this.estrogen,
    this.testosterone,
    this.location,
    this.doctor,
    this.notes,
  }) : id = id ?? const Uuid().v4() {
    _validate();
  }

  /// Validates bloodwork fields
  void _validate() {
    if (estrogen != null && estrogen! < 0) {
      throw BloodworkException('Estrogen level cannot be negative');
    }

    if (testosterone != null && testosterone! < 0) {
      throw BloodworkException('Testosterone level cannot be negative');
    }

    // For past or present dates with bloodwork type, require at least one hormone level
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (!recordDate.isAfter(today) &&
        appointmentType == AppointmentType.bloodwork &&
        estrogen == null &&
        testosterone == null) {
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

      return Bloodwork(
        id: json['id'] as String,
        date: DateTime.parse(json['date']),
        appointmentType: parsedType,
        estrogen: json['estrogen'] != null
            ? (json['estrogen'] as num).toDouble()
            : null,
        testosterone: json['testosterone'] != null
            ? (json['testosterone'] as num).toDouble()
            : null,
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
    double? estrogen,
    double? testosterone,
    String? location,
    String? doctor,
    String? notes,
  }) {
    return Bloodwork(
      id: id,
      date: date ?? this.date,
      appointmentType: appointmentType ?? this.appointmentType,
      estrogen: estrogen ?? this.estrogen,
      testosterone: testosterone ?? this.testosterone,
      location: location ?? this.location,
      doctor: doctor ?? this.doctor,
      notes: notes ?? this.notes,
    );
  }
}
