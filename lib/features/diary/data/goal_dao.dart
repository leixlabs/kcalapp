import '../../../data/database/database.dart';
import '../domain/daily_goal.dart';

class GoalDao {
  final AppDatabase db;
  GoalDao(this.db);

  Future<DailyGoal?> getGoalForDate(DateTime date) async {
    final dateStr = date.toIso8601String();
    final rows = await db.rawQuery(
      'SELECT * FROM daily_goals WHERE effective_date <= ? ORDER BY effective_date DESC LIMIT 1',
      [dateStr],
    );
    if (rows.isEmpty) return null;
    return _toDomain(rows.first);
  }

  Future<List<DailyGoal>> getAllGoals() async {
    final rows = await db.rawQuery('SELECT * FROM daily_goals ORDER BY effective_date DESC');
    return rows.map(_toDomain).toList();
  }

  Future<int> saveGoal(DailyGoal goal) async {
    final dateStr = goal.effectiveDate.toIso8601String();
    final existing = await db.rawQuery(
      'SELECT id FROM daily_goals WHERE effective_date = ?',
      [dateStr],
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.rawUpdate(
        'UPDATE daily_goals SET kcal = ?, carbs_g = ?, protein_g = ?, fat_g = ? WHERE id = ?',
        [goal.kcal, goal.carbsG, goal.proteinG, goal.fatG, id],
      );
      return id;
    }
    return db.rawInsert(
      'INSERT INTO daily_goals (effective_date, kcal, carbs_g, protein_g, fat_g) VALUES (?, ?, ?, ?, ?)',
      [dateStr, goal.kcal, goal.carbsG, goal.proteinG, goal.fatG],
    );
  }

  DailyGoal _toDomain(Map<String, dynamic> row) {
    return DailyGoal(
      id: row['id'] as int?,
      effectiveDate: DateTime.parse(row['effective_date'] as String),
      kcal: (row['kcal'] as num?)?.toDouble() ?? 0,
      carbsG: (row['carbs_g'] as num?)?.toDouble() ?? 0,
      proteinG: (row['protein_g'] as num?)?.toDouble() ?? 0,
      fatG: (row['fat_g'] as num?)?.toDouble() ?? 0,
    );
  }
}
