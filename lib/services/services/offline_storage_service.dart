import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineStorageService {
  static Database? _db;

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ocutune_offline.db');

    _db = await openDatabase(
      path,
      version: 2, // ny version for migrering
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
    if (type == 'sensor_log') {
      await _db!.insert('patient_sensor_log', {
        'sensor_id': data['sensor_id'],
        'patient_id': data['patient_id'],
        'started_at': data['timestamp'],
        'ended_at': data['ended_at'], // Optional: can be null
        'status': data['status'],     // Optional: 'connected', 'disconnected', etc.
      });
      return;
    }

    // Default fallback
    await _db!.insert(
      'unsynced_data',
      {
        'type': type,
        'json': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    return await _db!.query('unsynced_data', orderBy: 'created_at ASC');
  }

  static Future<void> deleteById(int id) async {
    await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
  }
}
