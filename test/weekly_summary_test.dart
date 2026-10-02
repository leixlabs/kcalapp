import 'package:flutter_test/flutter_test.dart';
import 'package:calory/features/diary/application/weekly_summary.dart';
import 'package:calory/features/diary/domain/food_category.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';

void main() {
  group('WeeklySummary', () {
    test('counts recorded days and averages only days with estimated kcal', () {
      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [
          _meal(monday, kcal: 100),
          _meal(monday.add(const Duration(days: 1)), kcal: 200),
          _meal(monday.add(const Duration(days: 1))),
        ],
      );

      expect(summary.recordedDays, 2);
      expect(summary.averageKcalOnEstimatedDays, 150);
    });

    test('suggests the category with the lowest guideline progress', () {
      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [
          _meal(monday, categoryId: FoodCategory.grains.id, weightG: 500),
          _meal(
            monday.add(const Duration(days: 1)),
            categoryId: FoodCategory.grains.id,
            weightG: 500,
          ),
          _meal(
            monday.add(const Duration(days: 2)),
            categoryId: FoodCategory.vegetablesAndFruits.id,
            weightG: 500,
          ),
        ],
      );

      expect(summary.focusCategory, FoodCategory.meatEggsAndSeafood);
      expect(summary.nextWeekFocus, contains('肉、蛋或水产'));
    });

    test(
      'keeps the recommendation generic when there are too few recorded days',
      () {
        final date = DateTime(2026, 9, 28);
        final summary = WeeklySummary(
          weekStart: date,
          meals: [
            _meal(date, categoryId: FoodCategory.grains.id, weightG: 500),
          ],
        );

        expect(summary.focusCategory, isNull);
        expect(summary.nextWeekFocus, contains('继续记录'));
      },
    );

    test('selects up to three photos from different days', () {
      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [
          _meal(monday, photoPath: '/one.jpg'),
          _meal(monday, photoPath: '/same-day.jpg'),
          _meal(monday.add(const Duration(days: 2)), photoPath: '/middle.jpg'),
          _meal(monday.add(const Duration(days: 6)), photoPath: '/last.jpg'),
        ],
      );

      expect(summary.photoMeals.map((meal) => meal.photoPath), [
        '/one.jpg',
        '/middle.jpg',
        '/last.jpg',
      ]);
    });
  });
}

Meal _meal(
  DateTime date, {
  double kcal = 0,
  double weightG = 100,
  String? categoryId,
  String? photoPath,
}) {
  return Meal(
    dateTime: date,
    mealType: MealType.lunch,
    name: '测试餐',
    photoPath: photoPath,
    foodItems: kcal == 0 && categoryId == null
        ? const []
        : [
            FoodItem(
              name: '测试食材',
              categoryId: categoryId,
              weightG: weightG,
              kcal: kcal,
              carbsG: 0,
              proteinG: 0,
              fatG: 0,
            ),
          ],
    createdAt: date,
    updatedAt: date,
  );
}
