import '../../../data/database/database.dart';
import '../domain/meal_review.dart';
import '../domain/meal_type.dart';

class MealReviewDao {
  final AppDatabase db;
  MealReviewDao(this.db);

  Future<MealReview?> get(DateTime date, MealType mealType) async {
    final day = _day(date);
    final rows = await db.rawQuery(
      'SELECT * FROM meal_reviews WHERE date = ? AND meal_type = ?',
      [day, mealType.name],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return MealReview(
      date: DateTime.parse(row['date'] as String),
      mealType: MealType.fromString(row['meal_type'] as String?),
      content: row['content'] as String?,
      status: MealReviewStatus.values.firstWhere(
        (status) => status.name == row['status'],
        orElse: () => MealReviewStatus.idle,
      ),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> upsert(MealReview review) => db.rawInsert(
    '''INSERT INTO meal_reviews (date, meal_type, content, status, updated_at)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(date, meal_type) DO UPDATE SET
         content = excluded.content,
         status = excluded.status,
         updated_at = excluded.updated_at''',
    [
      _day(review.date),
      review.mealType.name,
      review.content,
      review.status.name,
      review.updatedAt.toIso8601String(),
    ],
  );

  String _day(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  /// 应用启动时将上次被中断（进程被杀）的「刷新中」评价标记为失败，
  /// 否则首页会一直停在「更新中」。评价内容保留，用户可手动重新生成。
  Future<void> markInterruptedRefreshesFailed() async {
    await db.rawUpdate(
      'UPDATE meal_reviews SET status = ?, updated_at = ? WHERE status = ?',
      [
        MealReviewStatus.failed.name,
        DateTime.now().toIso8601String(),
        MealReviewStatus.refreshing.name,
      ],
    );
  }
}
