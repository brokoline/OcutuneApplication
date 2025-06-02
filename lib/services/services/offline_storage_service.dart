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
      final dynamic patientId = data['patient_id'];
      final dynamic sensorId = data['sensor_id'];

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

      // Konverter spectrum til double[]
      data['spectrum'] = spectrum.map((e) => (e as num).toDouble()).toList();

      // fallback værdier hvis nødvendigt
      data['light_type'] = data['light_type'] ?? 'Unknown';
      data['action_required'] = data['action_required'] ?? 0;
      data['timestamp'] = data['timestamp'] ?? DateTime.now().toIso8601String();

      // Dublet-tjek baseret på patient_id, sensor_id og timestamp
      final timestamp = data['timestamp'];
      final jsonLike = '%"timestamp":"$timestamp"%';

      final existing = await _db!.query(
        'unsynced_data',
        where: 'type = ? AND json LIKE ?',
        whereArgs: ['light', jsonLike],
      );

      final alreadyExists = existing.any((row) {
        final decoded = jsonDecode(row['json'] as String);
        return decoded['patient_id'] == patientId &&
            decoded['sensor_id'] == sensorId;
      });

      if (alreadyExists) {
        print("⚠️ Dublet fundet – data ikke gemt for timestamp $timestamp");
        return;
      }
    }

    if (type == 'sensor_log') {
      await _db!.insert('patient_sensor_log', {
        'sensor_id': data['sensor_id'],
        'patient_id': data['patient_id'],
        'started_at': data['timestamp'],
        'ended_at': data['ended_at'],
        'status': data['status'],
      });
      return;
    }

    // 👇 Til sidst, indsæt i offline tabellen
    await _db!.insert(
      'unsynced_data',
      {
        'type': type,
        'json': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteInvalidSensorData() async {
    if (_db == null) return;

    // Eksempel 1: hvis “ugyldig” = json: ..."sensor_id":-1...
    await _db!.delete(
      'unsynced_data',
      where: 'json LIKE ?',
      whereArgs: ['%"sensor_id":-1%'],
    );

    // Eksempel 2: hvis du også vil fjerne de poster, hvor sensor_id eksplícit er null
    await _db!.delete(
      'unsynced_data',
      where: 'json LIKE ?',
      whereArgs: ['%"sensor_id":null%'],
    );

    // ───────────────────────────────────────────────────────────────────────────
    // NYT: Fjern alle 'light'‐poster der slet ikke indeholder "sensor_id" i JSON
    // (dvs. rækker hvor 'sensor_id' mangler fuldstændigt)
    await _db!.delete(
      'unsynced_data',
      where: 'type = ? AND json NOT LIKE ?',
      whereArgs: ['light', '%"sensor_id"%'],
    );
    // ───────────────────────────────────────────────────────────────────────────
  }

  /// NY MEtODE: Rens batteri‐tabellen, så rækker med ugyldigt sensor_id/patient_id fjernes
  static Future<void> deleteInvalidBatteryData() async {
    if (_db == null) return;

    // Slet poster hvor sensor_id = -1
    await _db!.delete(
      'client_battery_status',
      where: 'sensor_id = ?',
      whereArgs: [-1],
    );

    // Slet poster hvor sensor_id IS NULL
    await _db!.delete(
      'client_battery_status',
      where: 'sensor_id IS NULL',
    );

    // Evt. slet poster hvor patient_id = -1 (valgfrit, hvis du også vil renses her)
    await _db!.delete(
      'client_battery_status',
      where: 'patient_id = ?',
      whereArgs: ['-1'],
    );

    print('🗑️ Ugyldige batteri‐poster (klient) er slettet');
  }


  static Future<void> deleteInvalidLightData() async {
    await _db!.delete(
      'unsynced_data',
      where: 'type = ? AND json LIKE ?',
      whereArgs: ['light', '%"patient_id":-1%'],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    return await _db!.query('unsynced_data', orderBy: 'created_at ASC');
  }

  static Future<void> deleteById(int id) async {
    await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
  }
}
