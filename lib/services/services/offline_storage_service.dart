import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineStorageService {
  static Database? _db;

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

  static Future<void> saveLocally({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (_db == null) return;

    if (type == 'light') {
      final patientId = data['patient_id'];
      final sensorId  = data['sensor_id'];

      debugPrint("Kontrollér patientId/sensorId i saveLocally: $patientId / $sensorId");

      if (patientId == null || sensorId == null || patientId == -1 || sensorId == -1) {
        debugPrint("Afvist: Ugyldig patientId/sensorId: $patientId/$sensorId");
        return;
      }

      data['light_type']     = data['light_type']      ?? 'Unknown';
      data['action_required']= data['action_required'] ?? 0;
      data['timestamp']      = data['timestamp']       ?? DateTime.now().toIso8601String();
      data['der']            = data['der']            ?? 0.0;
      data['exposure_score'] = data['exposure_score'] ?? 0.0;
      data['lux_level']      = data['lux_level']      ?? 0;
      data['melanopic_edi']  = data['melanopic_edi']  ?? 0.0;
      data['illuminance']    = data['illuminance']    ?? 0.0;

      final timestamp = data['timestamp'];
      final jsonLike  = '%"timestamp":"$timestamp"%';
      final existing = await _db!.query(
        'unsynced_data',
        where: 'type = ? AND json LIKE ?',
        whereArgs: ['light', jsonLike],
      );
      final alreadyExists = existing.any((row) {
        final decoded = jsonDecode(row['json'] as String) as Map<String, dynamic>;
        return decoded['patient_id'] == patientId && decoded['sensor_id'] == sensorId;
      });
      if (alreadyExists) {
        debugPrint("Dublet fundet - data ikke gemt for timestamp $timestamp");
        return;
      }
    }

    // ─── Sensor-log entries ────────────────────────────────────────────────
    if (type == 'patient_sensor_log') {
      await _db!.insert(
        'patient_sensor_log',
        {
          'sensor_id': data['sensor_id'],
          'patient_id': data['patient_id'],
          'started_at': data['started_at'],
          if (data.containsKey('ended_at')) 'ended_at': data['ended_at'],
          'status': data['status'] ?? 'active',
        },
      );
    }

    // ─── Generic fallback ───────────────────────────────────────────────────
    await _db!.insert(
      'unsynced_data',
      {
        'type': type,
        'json': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateLogEntry(
      String startedAt,
      Map<String, dynamic> updates,
      ) async {
    if (_db == null) {
      throw Exception('Database not initialized');
    }

    try {
      final count = await _db!.update(
        'patient_sensor_log',
        updates,
        where: 'started_at = ?',
        whereArgs: [startedAt],
      );

      if (count == 0) {
        debugPrint('No rows updated for started_at: $startedAt');
      }
    } catch (e) {
      debugPrint('Failed to update log entry: $e');
      rethrow;
    }
  }

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

  static Future<void> purgeInvalidUnsyncedData() async {
    if (_db == null) return;

    final rows = await _db!.query('unsynced_data', columns: ['id', 'json']);
    for (final row in rows) {
      final id   = row['id'] as int;
      final json = row['json'] as String;
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        const requiredFields = [
          'patient_id',
          'sensor_id',
          'timestamp',
          'lux_level',
          'melanopic_edi',
          'illuminance',
          'der',
          'exposure_score',
          'action_required',
        ];

        final missingOrNull = requiredFields.any((key) =>
        !data.containsKey(key) || data[key] == null
        );
        if (missingOrNull) {
          await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
          debugPrint('Fjernet ugyldig unsynced_data id=$id');
        }
      } catch (e) {
        await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
        debugPrint('Fjernet corrupt JSON id=$id: $e');
      }
    }
  }



  static Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    if (_db == null) return [];
    return await _db!.query(
      'unsynced_data',
      where: 'type = ? AND sync_status IS NULL',
      whereArgs: ['patient_sensor_log'],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    if (_db == null) return [];
    return await _db!.query('unsynced_data', orderBy: 'created_at ASC');
  }

  static Future<void> deleteById(int id) async {
    if (_db == null) return;
    await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
  }

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

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}