//
//  database_service.dart
//
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:nokken/src/features/medication_tracker/models/medication.dart';

class DatabaseException implements Exception {
  final String message;
  final dynamic error;
  DatabaseException(this.message, [this.error]);

  @override
  String toString() =>
      'DatabaseException: $message${error != null ? ' ($error)' : ''}';
}

class DatabaseService {
  static Database? _database;
  static const int _currentVersion = 3; // Increase for migrations

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

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
        // to reset db: flutter clean
        // onUpgrade: (db, oldVersion, newVersion) async {},
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database', e);
    }
  }

  Future<void> _createDatabase(Database db) async {
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
  }

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

  Future<void> deleteMedication(String id) async {
    try {
      final db = await database;
      await db.delete(
        'medications',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete medication', e);
    }
  }

  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('medications');
      return maps.map(_mapToMedication).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch medications', e);
    }
  }
}
