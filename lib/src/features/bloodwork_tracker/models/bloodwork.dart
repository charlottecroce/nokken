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

/// Primary model for bloodwork lab test data
class Bloodwork {
  final String id;
  final DateTime date;
  final double? estrogen; // pg/mL
  final double? testosterone; // ng/dL
  final String? notes;

  /// Constructor with validation
  Bloodwork({
    String? id,
    required this.date,
    this.estrogen,
    this.testosterone,
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

    // For past or present dates, require at least one hormone level
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (!recordDate.isAfter(today) &&
        estrogen == null &&
        testosterone == null) {
      throw BloodworkException(
          'At least one hormone level must be provided for past or present dates');
    }
  }

  /// Convert to JSON format for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'estrogen': estrogen,
      'testosterone': testosterone,
      'notes': notes?.trim(),
    };
  }

  /// Create a Bloodwork instance from JSON (database record)
  factory Bloodwork.fromJson(Map<String, dynamic> json) {
    try {
      return Bloodwork(
        id: json['id'] as String,
        date: DateTime.parse(json['date']),
        estrogen: json['estrogen'] != null
            ? (json['estrogen'] as num).toDouble()
            : null,
        testosterone: json['testosterone'] != null
            ? (json['testosterone'] as num).toDouble()
            : null,
        notes: json['notes'] as String?,
      );
    } catch (e) {
      throw BloodworkException('Invalid bloodwork data: $e');
    }
  }

  /// Create a copy of this bloodwork with updated fields
  Bloodwork copyWith({
    DateTime? date,
    double? estrogen,
    double? testosterone,
    String? notes,
  }) {
    return Bloodwork(
      id: id,
      date: date ?? this.date,
      estrogen: estrogen ?? this.estrogen,
      testosterone: testosterone ?? this.testosterone,
      notes: notes ?? this.notes,
    );
  }
}
