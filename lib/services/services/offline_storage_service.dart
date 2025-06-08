import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineStorageService {
  static Database? _db;

  /// Initialize the local SQLite database
  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ocutune_offline.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS unsynced_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            json TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS patient_sensor_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sensor_id INTEGER NOT NULL,
            patient_id INTEGER NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            status TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS patient_sensor_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sensor_id INTEGER NOT NULL,
              patient_id INTEGER NOT NULL,
              started_at TEXT NOT NULL,
              ended_at TEXT,
              status TEXT
            )
          ''');
        }
      },
    );
  }

  /// Save a data payload locally in the unsynced queue
  static Future<void> saveLocally({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (_db == null) return;

    if (type == 'light') {
      final patientId = data['patient_id'];
      final sensorId = data['sensor_id'];

      print("💡 Kontrollér patientId/sensorId i saveLocally: $patientId / $sensorId");

      if (patientId == null || sensorId == null || patientId == -1 || sensorId == -1) {
        print("⚠️ Afvist: Ugyldig patientId/sensorId: $patientId/$sensorId");
        return;
      }

      final spectrum = data['spectrum'];
      if (spectrum is! List) {
        print("⚠️ Afvist: spectrum er ikke List");
        return;
      }

      // Ensure proper types
      data['spectrum'] = spectrum.map((e) => (e as num).toDouble()).toList();
      data['light_type']      = data['light_type']      ?? 'Unknown';
      data['action_required'] = data['action_required'] ?? 0;
      data['timestamp']       = data['timestamp']       ?? DateTime.now().toIso8601String();

      // Duplicate check based on timestamp
      final timestamp = data['timestamp'];
      final jsonLike = '%"timestamp":"$timestamp"%';
      final existing = await _db!.query(
        'unsynced_data',
        where: 'type = ? AND json LIKE ?',
        whereArgs: ['light', jsonLike],
      );
      final alreadyExists = existing.any((row) {
        final decoded = jsonDecode(row['json'] as String);
        return decoded['patient_id'] == patientId && decoded['sensor_id'] == sensorId;
      });
      if (alreadyExists) {
        print("⚠️ Dublet fundet – data ikke gemt for timestamp $timestamp");
        return;
      }
    }

    if (type == 'sensor_log') {
      await _db!.insert(
        'patient_sensor_log',
        {
          'sensor_id':  data['sensor_id'],
          'patient_id': data['patient_id'],
          'started_at': data['timestamp'],
          'ended_at':   data['ended_at'],
          'status':     data['status'],
        },
      );
      return;
    }

    await _db!.insert(
      'unsynced_data',
      {
        'type': type,
        'json': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete invalid entries before syncing
  static Future<void> deleteInvalidLightData() async {
    if (_db == null) return;
    await _db!.delete(
      'unsynced_data',
      where: 'type = ? AND json LIKE ?',
      whereArgs: ['light', '%"lux_level":null%'],
    );
    await _db!.delete(
      'unsynced_data',
      where: 'type = ? AND json LIKE ?',
      whereArgs: ['light', '%"illuminance":null%'],
    );
    await _db!.delete(
      'unsynced_data',
      where: 'type = ? AND json LIKE ?',
      whereArgs: ['light', '%"light_type":"Unknown"%'],
    );
  }

  /// Fetch all unsynced entries in order
  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    if (_db == null) return [];
    return await _db!.query('unsynced_data', orderBy: 'created_at ASC');
  }

  /// Delete a single entry by its ID
  static Future<void> deleteById(int id) async {
    if (_db == null) return;
    await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
  }

  /// Stream unsynced records of a specific type for a patient
  static Stream<Map<String, dynamic>> streamRecords({
    required String type,
    required int patientId,
  }) async* {
    if (_db == null) {
      yield* const Stream.empty();
      return;
    }
    final rows = await _db!.query(
      'unsynced_data',
      columns: ['json'],
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at ASC',
    );
    for (final row in rows) {
      final data = jsonDecode(row['json'] as String) as Map<String, dynamic>;
      if (data['patient_id'].toString() == patientId.toString()) {
        yield data;
      }
    }
  }
}
