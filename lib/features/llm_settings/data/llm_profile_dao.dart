import '../../../data/database/database.dart';
import '../domain/llm_profile.dart';

class LlmProfileDao {
  final AppDatabase db;
  LlmProfileDao(this.db);

  Future<List<LlmProfile>> getAll() async {
    final rows = await db.rawQuery('SELECT * FROM llm_profiles ORDER BY created_at DESC');
    return rows.map(_toDomain).toList();
  }

  Future<LlmProfile?> getActive() async {
    final rows = await db.rawQuery('SELECT * FROM llm_profiles WHERE is_active = 1 LIMIT 1');
    if (rows.isEmpty) return null;
    return _toDomain(rows.first);
  }

  Future<int> insertProfile(LlmProfile profile) async {
    final database = await db.database;
    return database.transaction((tx) async {
      if (profile.isActive) {
        await tx.rawUpdate('UPDATE llm_profiles SET is_active = 0 WHERE is_active = 1');
      }
      return tx.rawInsert(
        'INSERT INTO llm_profiles (display_name, base_url, model, timeout_seconds, is_active) VALUES (?, ?, ?, ?, ?)',
        [
          profile.displayName,
          profile.baseUrl,
          profile.model,
          profile.timeoutSeconds,
          profile.isActive ? 1 : 0,
        ],
      );
    });
  }

  Future<void> updateProfile(LlmProfile profile) async {
    await db.rawUpdate(
      'UPDATE llm_profiles SET display_name = ?, base_url = ?, model = ?, timeout_seconds = ? WHERE id = ?',
      [
        profile.displayName,
        profile.baseUrl,
        profile.model,
        profile.timeoutSeconds,
        profile.id,
      ],
    );
  }

  Future<void> activateProfile(int id) async {
    final database = await db.database;
    await database.transaction((tx) async {
      await tx.rawUpdate('UPDATE llm_profiles SET is_active = 0 WHERE is_active = 1');
      await tx.rawUpdate('UPDATE llm_profiles SET is_active = 1 WHERE id = ?', [id]);
    });
  }

  Future<void> deleteProfile(int id) async {
    final database = await db.database;
    await database.transaction((tx) async {
      final active = await tx.rawQuery(
        'SELECT is_active FROM llm_profiles WHERE id = ?',
        [id],
      );
      await tx.rawDelete('DELETE FROM llm_profiles WHERE id = ?', [id]);
      final wasActive = active.isNotEmpty && (active.first['is_active'] as int? ?? 0) == 1;
      if (wasActive) {
        final remaining = await tx.rawQuery(
          'SELECT id FROM llm_profiles ORDER BY created_at DESC LIMIT 1',
        );
        if (remaining.isNotEmpty) {
          await tx.rawUpdate(
            'UPDATE llm_profiles SET is_active = 1 WHERE id = ?',
            [remaining.first['id']],
          );
        }
      }
    });
  }

  LlmProfile _toDomain(Map<String, dynamic> row) {
    return LlmProfile(
      id: row['id'] as int?,
      displayName: row['display_name'] as String? ?? '',
      baseUrl: row['base_url'] as String? ?? '',
      model: row['model'] as String? ?? '',
      timeoutSeconds: row['timeout_seconds'] as int? ?? 30,
      isActive: (row['is_active'] as int?) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
