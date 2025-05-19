import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class OfflineStorageService {
  static Database? _db;

  // Init database (kald i main() el. første gang)
  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ocutune_offline.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE IF NOT EXISTS unsynced_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            json TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  // Gem en række
  static Future<void> saveLocally({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _db!.insert(
      'unsynced_data',
      {
        'type': type,
        'json': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Hent alt
  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    return await _db!.query('unsynced_data', orderBy: 'created_at ASC');
  }

  // Slet én
  static Future<void> deleteById(int id) async {
    await _db!.delete('unsynced_data', where: 'id = ?', whereArgs: [id]);
  }
}
