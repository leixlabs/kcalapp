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
    await db.rawUpdate('UPDATE llm_profiles SET is_active = 0 WHERE is_active = 1');
    return db.rawInsert(
      'INSERT INTO llm_profiles (display_name, base_url, model, timeout_seconds, is_active) VALUES (?, ?, ?, ?, ?)',
      [
        profile.displayName,
        profile.baseUrl,
        profile.model,
        profile.timeoutSeconds,
        profile.isActive ? 1 : 0,
      ],
    );
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
    await db.rawUpdate('UPDATE llm_profiles SET is_active = 0 WHERE is_active = 1');
    await db.rawUpdate('UPDATE llm_profiles SET is_active = 1 WHERE id = ?', [id]);
  }

  Future<void> deleteProfile(int id) async {
    await db.rawDelete('DELETE FROM llm_profiles WHERE id = ?', [id]);
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
