//
//  database_service.dart
//  Service for handling database operations
//
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';

/// Custom exception for database-related errors
class DatabaseException implements Exception {
  final String message;
  final dynamic error;
  DatabaseException(this.message, [this.error]);

  @override
  String toString() =>
      'DatabaseException: $message${error != null ? ' ($error)' : ''}';
}

/// Model for tracking when medications are taken
class TakenMedication {
  final String medicationId;
  final DateTime date;
  final String timeSlot;
  final bool taken;
  final String? customKey;

  TakenMedication({
    required this.medicationId,
    required this.date,
    required this.timeSlot,
    required this.taken,
    this.customKey,
  });

  /// Generate a unique key for this record - normalize date to prevent time issues
  String get uniqueKey {
    if (customKey != null) {
      return customKey!;
    }

    // Create a normalized date string (just year-month-day, no time)
    final normalizedDate =
        DateTime(date.year, date.month, date.day).toIso8601String();
    return '$medicationId-$normalizedDate-$timeSlot';
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    // Always normalize the date when saving to database
    final normalizedDate =
        DateTime(date.year, date.month, date.day).toIso8601String();

    final map = {
      'medication_id': medicationId,
      'date': normalizedDate,
      'time_slot': timeSlot,
      'taken': taken ? 1 : 0,
    };

// Add custom key if provided (cast to Object to satisfy type requirements)
    if (customKey != null) {
      map['custom_key'] = customKey as Object;
    }

    return map;
  }

  /// Create from database map
  factory TakenMedication.fromMap(Map<String, dynamic> map) {
    try {
      final date = DateTime.parse(map['date']);
      // Always normalize the date to ensure consistency
      final normalizedDate = DateTime(date.year, date.month, date.day);

      return TakenMedication(
        medicationId: map['medication_id'],
        date: normalizedDate,
        timeSlot: map['time_slot'],
        taken: map['taken'] == 1,
        customKey: map['custom_key'],
      );
    } catch (e) {
      // Return a default value in case of error
      return TakenMedication(
        medicationId: map['medication_id'] ?? 'unknown',
        date: DateTime.now(),
        timeSlot: map['time_slot'] ?? 'unknown',
        taken: map['taken'] == 1,
      );
    }
  }
}

/// Service that manages database operations for the application
class DatabaseService {
  static Database? _database;
  static const int _currentVersion = 3; // Increase version for schema update

  /// Get the database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database connection
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final pathToDb = path.join(dbPath, 'nokken.db');

      return await openDatabase(
        pathToDb,
        version: _currentVersion,
        onCreate: (db, version) async {
          await _createDatabase(db);
        },
        // No onUpgrade - for testing we'll reset the database
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database', e);
    }
  }

  /// Create the database schema
  Future<void> _createDatabase(Database db) async {
    // Create medications table
    await db.execute('''
      CREATE TABLE medications(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        startDate TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        timeOfDay TEXT NOT NULL,
        daysOfWeek TEXT NOT NULL,
        currentQuantity INTEGER NOT NULL,
        refillThreshold INTEGER NOT NULL,
        notes TEXT,
        medicationType TEXT NOT NULL,
        injectionFrequency TEXT,
        drawingNeedleType TEXT,
        drawingNeedleCount INTEGER,
        drawingNeedleRefills INTEGER,
        injectingNeedleType TEXT,
        injectingNeedleCount INTEGER,
        injectingNeedleRefills INTEGER,
        injectionSiteNotes TEXT
      )
    ''');

    // Create taken_medications table
    await db.execute('''
      CREATE TABLE taken_medications(
        medication_id TEXT NOT NULL,
        date TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        taken INTEGER NOT NULL,
        custom_key TEXT,
        PRIMARY KEY (custom_key)
      )
    ''');

    // Updated bloodwork table with new fields
    await db.execute('''
      CREATE TABLE bloodwork(
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        appointmentType TEXT NOT NULL,
        estrogen REAL,
        testosterone REAL,
        hormone_readings TEXT,
        location TEXT,
        doctor TEXT,
        notes TEXT
      )
    ''');
  }

  /// Convert a Medication object to a database map
  Map<String, dynamic> _medicationToMap(Medication medication) {
    // Start with basic fields
    final map = {
      'id': medication.id,
      'name': medication.name.trim(),
      'dosage': medication.dosage.trim(),
      'startDate': medication.startDate.toIso8601String(),
      'frequency': medication.frequency,
      'timeOfDay':
          medication.timeOfDay.map((t) => t.toIso8601String()).join(','),
      'daysOfWeek': medication.daysOfWeek.toList().join(','),
      'currentQuantity': medication.currentQuantity,
      'refillThreshold': medication.refillThreshold,
      'notes': medication.notes?.trim(),
      'medicationType': medication.medicationType.toString().split('.').last,
    };

    // Add injection details if present, storing each field directly
    if (medication.injectionDetails != null) {
      map.addAll({
        'drawingNeedleType': medication.injectionDetails!.drawingNeedleType,
        'drawingNeedleCount': medication.injectionDetails!.drawingNeedleCount,
        'drawingNeedleRefills':
            medication.injectionDetails!.drawingNeedleRefills,
        'injectingNeedleType': medication.injectionDetails!.injectingNeedleType,
        'injectingNeedleCount':
            medication.injectionDetails!.injectingNeedleCount,
        'injectingNeedleRefills':
            medication.injectionDetails!.injectingNeedleRefills,
        'injectionSiteNotes': medication.injectionDetails!.injectionSiteNotes,
        'injectionFrequency':
            medication.injectionDetails!.frequency.toString().split('.').last,
      });
    } else {
      // Set null for all injection-related fields for non-injection medications
      map.addAll({
        'drawingNeedleType': null,
        'drawingNeedleCount': null,
        'drawingNeedleRefills': null,
        'injectingNeedleType': null,
        'injectingNeedleCount': null,
        'injectingNeedleRefills': null,
        'injectionSiteNotes': null,
        'injectionFrequency': null,
      });
    }

    return map;
  }

  /// Convert a database map to a Medication object
  Medication _mapToMedication(Map<String, dynamic> map) {
    // Convert enum string back to enum value
    final medicationType = MedicationType.values.firstWhere(
      (e) => e.toString() == 'MedicationType.${map['medicationType']}',
    );

    // Create injection details if this is an injection medication
    InjectionDetails? injectionDetails;
    if (medicationType == MedicationType.injection) {
      final frequency = InjectionFrequency.values.firstWhere(
        (e) =>
            e.toString() == 'InjectionFrequency.${map['injectionFrequency']}',
      );

      injectionDetails = InjectionDetails(
        drawingNeedleType: map['drawingNeedleType'] as String,
        drawingNeedleCount: map['drawingNeedleCount'] as int,
        drawingNeedleRefills: map['drawingNeedleRefills'] as int,
        injectingNeedleType: map['injectingNeedleType'] as String,
        injectingNeedleCount: map['injectingNeedleCount'] as int,
        injectingNeedleRefills: map['injectingNeedleRefills'] as int,
        injectionSiteNotes: map['injectionSiteNotes'] as String? ?? '',
        frequency: frequency,
      );
    }

    // Create the medication object
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      frequency: map['frequency'] as int,
      timeOfDay: (map['timeOfDay'] as String)
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => DateTime.parse(t))
          .toList(),
      daysOfWeek: (map['daysOfWeek'] as String)
          .split(',')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toSet(),
      currentQuantity: map['currentQuantity'] as int,
      refillThreshold: map['refillThreshold'] as int,
      notes: map['notes'] as String?,
      medicationType: medicationType,
      injectionDetails: injectionDetails,
    );
  }

  //----------------------------------------------------------------------------
  // MEDICATION CRUD OPERATIONS
  //----------------------------------------------------------------------------

  /// Insert a new medication into the database
  Future<void> insertMedication(Medication medication) async {
    try {
      final db = await database;
      await db.insert(
        'medications',
        _medicationToMap(medication),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert medication', e);
    }
  }

  /// Update an existing medication in the database
  Future<void> updateMedication(Medication medication) async {
    try {
      final db = await database;
      await db.update(
        'medications',
        _medicationToMap(medication),
        where: 'id = ?',
        whereArgs: [medication.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update medication', e);
    }
  }

  /// Delete a medication and its taken records
  Future<void> deleteMedication(String id) async {
    try {
      final db = await database;
      await db.delete(
        'medications',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Also delete any taken records for this medication
      await db.delete(
        'taken_medications',
        where: 'medication_id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete medication', e);
    }
  }

  /// Get all medications from the database
  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('medications');
      return maps.map(_mapToMedication).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch medications', e);
    }
  }

  //----------------------------------------------------------------------------
  // TAKEN MEDICATION OPERATIONS
  //----------------------------------------------------------------------------

  /// Mark a medication as taken or not taken, with optional custom key
  Future<void> setMedicationTakenWithCustomKey(String medicationId,
      DateTime date, String timeSlot, bool taken, String? customKey) async {
    try {
      final db = await database;
      final takenMed = TakenMedication(
        medicationId: medicationId,
        date: DateTime(date.year, date.month, date.day), // Strip time component
        timeSlot: timeSlot,
        taken: taken,
        customKey: customKey,
      );

      // If custom key is provided, we need to handle it specially
      if (customKey != null) {
        // First check if an entry with this custom key exists
        final existingEntries = await db.query(
          'taken_medications',
          where: 'custom_key = ?',
          whereArgs: [customKey],
        );

        if (existingEntries.isNotEmpty) {
          // Update existing entry
          await db.update(
            'taken_medications',
            takenMed.toMap(),
            where: 'custom_key = ?',
            whereArgs: [customKey],
          );
        } else {
          // Insert new entry
          await db.insert(
            'taken_medications',
            takenMed.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else {
        // Standard insert/replace for entries without custom key
        await db.insert(
          'taken_medications',
          takenMed.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw DatabaseException('Failed to save medication taken status', e);
    }
  }

  /// Legacy method for compatibility
  Future<void> setMedicationTaken(
      String medicationId, DateTime date, String timeSlot, bool taken) async {
    await setMedicationTakenWithCustomKey(
        medicationId, date, timeSlot, taken, null);
  }

  /// Get all medications taken on a specific date
  Future<Set<String>> getTakenMedicationsForDate(DateTime date) async {
    try {
      final db = await database;
      final dateStr =
          DateTime(date.year, date.month, date.day).toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        'taken_medications',
        where: 'date = ? AND taken = 1',
        whereArgs: [dateStr],
      );

      final result = <String>{};

      for (final map in maps) {
        final takenMed = TakenMedication.fromMap(map);

        // Add to result using custom key if available, otherwise use standard key
        if (takenMed.customKey != null) {
          result.add(takenMed.customKey!);
        } else {
          result.add(takenMed.uniqueKey);
        }
      }

      return result;
    } catch (e) {
      throw DatabaseException('Failed to fetch taken medications', e);
    }
  }

  /// Delete taken medication records older than the specified date
  Future<void> deleteTakenMedicationsOlderThan(DateTime date) async {
    try {
      final db = await database;
      final cutoffDate =
          DateTime(date.year, date.month, date.day).toIso8601String();

      await db.delete(
        'taken_medications',
        where: 'date < ?',
        whereArgs: [cutoffDate],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete old taken medications', e);
    }
  }

//----------------------------------------------------------------------------
// BLOODWORK CRUD OPERATIONS
//----------------------------------------------------------------------------

  /// Convert a Bloodwork object to a database map
  Map<String, dynamic> _bloodworkToMap(Bloodwork bloodwork) {
    final map = {
      'id': bloodwork.id,
      'date': bloodwork.date.toIso8601String(),
      'appointmentType': bloodwork.appointmentType.toString(),
      'location': bloodwork.location,
      'doctor': bloodwork.doctor,
      'notes': bloodwork.notes,
    };

    // Store hormone readings as JSON
    if (bloodwork.hormoneReadings.isNotEmpty) {
      map['hormone_readings'] =
          jsonEncode(bloodwork.hormoneReadings.map((r) => r.toJson()).toList());
    }

    return map;
  }

  /// Convert a database map to a Bloodwork object
  Bloodwork _mapToBloodwork(Map<String, dynamic> map) {
    try {
      // Parse appointment type from string
      AppointmentType parsedType;
      try {
        parsedType = AppointmentType.values.firstWhere(
            (e) => e.toString() == map['appointmentType'],
            orElse: () => AppointmentType.bloodwork);
      } catch (_) {
        // For backward compatibility with old records without appointmentType
        parsedType = AppointmentType.bloodwork;
      }

      // Parse hormone readings from JSON
      List<HormoneReading> hormoneReadings = [];

      if (map['hormone_readings'] != null) {
        try {
          final List<dynamic> decodedReadings =
              jsonDecode(map['hormone_readings']);
          hormoneReadings = decodedReadings
              .map((json) => HormoneReading.fromJson(json))
              .toList();
        } catch (e) {
          print('Error parsing hormone readings: $e');
        }
      }

      // If no hormone readings were found in JSON but legacy fields exist,
      // create hormone readings from them
      if (hormoneReadings.isEmpty) {
        if (map['estrogen'] != null) {
          hormoneReadings.add(HormoneReading(
            name: 'Estrogen',
            value: (map['estrogen'] as num).toDouble(),
            unit: 'pg/mL',
          ));
        }

        if (map['testosterone'] != null) {
          hormoneReadings.add(HormoneReading(
            name: 'Testosterone',
            value: (map['testosterone'] as num).toDouble(),
            unit: 'ng/dL',
          ));
        }
      }

      return Bloodwork(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        appointmentType: parsedType,
        hormoneReadings: hormoneReadings,
        location: map['location'] as String?,
        doctor: map['doctor'] as String?,
        notes: map['notes'] as String?,
      );
    } catch (e) {
      throw DatabaseException('Invalid bloodwork data: $e');
    }
  }

  /// Insert a new bloodwork record into the database
  Future<void> insertBloodwork(Bloodwork bloodwork) async {
    try {
      final db = await database;
      await db.insert(
        'bloodwork',
        _bloodworkToMap(bloodwork),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert bloodwork', e);
    }
  }

  /// Update an existing bloodwork record in the database
  Future<void> updateBloodwork(Bloodwork bloodwork) async {
    try {
      final db = await database;
      await db.update(
        'bloodwork',
        _bloodworkToMap(bloodwork),
        where: 'id = ?',
        whereArgs: [bloodwork.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update bloodwork', e);
    }
  }

  /// Delete a bloodwork record
  Future<void> deleteBloodwork(String id) async {
    try {
      final db = await database;
      await db.delete(
        'bloodwork',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete bloodwork', e);
    }
  }

  /// Get all bloodwork records from the database
  Future<List<Bloodwork>> getAllBloodwork() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bloodwork',
        orderBy: 'date DESC', // Most recent first
      );
      return maps.map(_mapToBloodwork).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch bloodwork records', e);
    }
  }

  /// Get a specific bloodwork record by ID
  Future<Bloodwork?> getBloodworkById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bloodwork',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return _mapToBloodwork(maps.first);
    } catch (e) {
      throw DatabaseException('Failed to fetch bloodwork', e);
    }
  }
}
