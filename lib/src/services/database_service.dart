//
//  database_service.dart
//  Service for handling database operations
//
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

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

  TakenMedication({
    required this.medicationId,
    required this.date,
    required this.timeSlot,
    required this.taken,
  });

  /// Generate a unique key for this record - normalize date to prevent time issues
  String get uniqueKey {
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
    return {
      'medication_id': medicationId,
      'date': normalizedDate,
      'time_slot': timeSlot,
      'taken': taken ? 1 : 0,
    };
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
  static const int _currentVersion = 1; // Will be used in future for DB updates

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
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 1) {
            // for updates to DB. for now just resetting
          }
        },
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
        PRIMARY KEY (medication_id, date, time_slot)
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

  /// Mark a medication as taken or not taken
  Future<void> setMedicationTaken(
      String medicationId, DateTime date, String timeSlot, bool taken) async {
    try {
      final db = await database;
      final takenMed = TakenMedication(
        medicationId: medicationId,
        date: DateTime(date.year, date.month, date.day), // Strip time component
        timeSlot: timeSlot,
        taken: taken,
      );

      await db.insert(
        'taken_medications',
        takenMed.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to save medication taken status', e);
    }
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

      final result = maps
          .map((map) => TakenMedication.fromMap(map))
          .where((takenMed) => takenMed.taken)
          .map((takenMed) => takenMed.uniqueKey)
          .toSet();

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
}
