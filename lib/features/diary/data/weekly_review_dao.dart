import '../../../data/database/database.dart';
import '../domain/weekly_review.dart';

class WeeklyReviewDao {
  final AppDatabase db;
  WeeklyReviewDao(this.db);

  Future<WeeklyReview?> get(DateTime weekStart) async {
    final rows = await db.rawQuery(
      'SELECT * FROM weekly_reviews WHERE week_start = ?',
      [_week(weekStart)],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return WeeklyReview(
      weekStart: DateTime.parse(row['week_start'] as String),
      happened: row['happened'] as String?,
      improvement: row['improvement'] as String?,
      signature: (row['signature'] as String?) ?? '',
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> upsert(WeeklyReview review) => db.rawInsert(
    '''INSERT INTO weekly_reviews (week_start, happened, improvement, signature, updated_at)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(week_start) DO UPDATE SET
         happened = excluded.happened,
         improvement = excluded.improvement,
         signature = excluded.signature,
         updated_at = excluded.updated_at''',
    [
      _week(review.weekStart),
      review.happened,
      review.improvement,
      review.signature,
      review.updatedAt.toIso8601String(),
    ],
  );

  String _week(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();
}
