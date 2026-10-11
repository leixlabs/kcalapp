import 'package:sqflite/sqflite.dart';

import 'database.dart';

class AppSettingsDao {
  final AppDatabase db;

  const AppSettingsDao(this.db);

  Future<String?> getValue(String key) async {
    final database = await db.database;
    final rows = await database.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setValue(String key, String value) async {
    final database = await db.database;
    await database.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
