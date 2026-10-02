import 'package:calory/features/diary/application/diary_providers.dart';
import 'package:calory/features/diary/domain/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mealReviewKey', () {
    test('归一化到当天零点，忽略时分秒', () {
      final morning = mealReviewKey(
        DateTime(2026, 10, 2, 10, 4, 30),
        MealType.breakfast,
      );
      final evening = mealReviewKey(
        DateTime(2026, 10, 2, 23, 59, 59),
        MealType.breakfast,
      );

      expect(morning, evening);
      expect(morning.date, DateTime(2026, 10, 2));
    });

    test('不同餐次或不同日期不相等', () {
      final base = mealReviewKey(DateTime(2026, 10, 2, 8), MealType.breakfast);

      expect(
        base == mealReviewKey(DateTime(2026, 10, 2, 9), MealType.lunch),
        isFalse,
      );
      expect(
        base == mealReviewKey(DateTime(2026, 10, 3, 8), MealType.breakfast),
        isFalse,
      );
    });
  });
}
