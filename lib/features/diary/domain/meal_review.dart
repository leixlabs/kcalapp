import 'meal_type.dart';

enum MealReviewStatus { idle, refreshing, completed, failed }

class MealReview {
  final DateTime date;
  final MealType mealType;
  final String? content;
  final MealReviewStatus status;
  final DateTime updatedAt;

  const MealReview({
    required this.date,
    required this.mealType,
    this.content,
    this.status = MealReviewStatus.idle,
    required this.updatedAt,
  });
}
