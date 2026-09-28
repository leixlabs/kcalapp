import '../../../data/database/database.dart';
import '../domain/daily_goal.dart';

class GoalDao {
  final AppDatabase db;
  GoalDao(this.db);

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<DailyGoal?> getGoalForDate(DateTime date) async {
    final dateStr = _dateKey(date);
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
    final dateStr = _dateKey(goal.effectiveDate);
    final database = await db.database;
    return database.transaction((tx) async {
      final existing = await tx.rawQuery(
        'SELECT id FROM daily_goals WHERE effective_date = ?',
        [dateStr],
      );
      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        await tx.rawUpdate(
          'UPDATE daily_goals SET kcal = ?, carbs_g = ?, protein_g = ?, fat_g = ? WHERE id = ?',
          [goal.kcal, goal.carbsG, goal.proteinG, goal.fatG, id],
        );
        return id;
      }
      return tx.rawInsert(
        'INSERT INTO daily_goals (effective_date, kcal, carbs_g, protein_g, fat_g) VALUES (?, ?, ?, ?, ?)',
        [dateStr, goal.kcal, goal.carbsG, goal.proteinG, goal.fatG],
      );
    });
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
