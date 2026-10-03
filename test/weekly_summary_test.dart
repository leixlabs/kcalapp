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

    test('summarizes the recorded week without AI', () {
      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [
          _meal(
            monday,
            kcal: 600,
            weightG: 300,
            categoryId: FoodCategory.grains.id,
          ),
          _meal(
            monday.add(const Duration(days: 1)),
            kcal: 400,
            categoryId: FoodCategory.vegetablesAndFruits.id,
          ),
        ],
      );

      expect(summary.happenedSummary, contains('记录了 2 天'));
      expect(summary.happenedSummary, contains('日均约 500 kcal'));
      expect(summary.happenedSummary, contains('谷薯类相对较多'));
    });

    test('keeps every photo in chronological order', () {
      final monday = DateTime(2026, 9, 28, 8);
      final summary = WeeklySummary(
        weekStart: DateTime(2026, 9, 28),
        meals: [
          _meal(monday, photoPath: '/one.jpg'),
          _meal(
            monday.add(const Duration(hours: 1)),
            photoPath: '/same-day.jpg',
          ),
          _meal(monday.add(const Duration(days: 2)), photoPath: '/middle.jpg'),
          _meal(monday.add(const Duration(days: 6)), photoPath: '/last.jpg'),
        ],
      );

      expect(summary.photoMeals.map((meal) => meal.photoPath), [
        '/one.jpg',
        '/same-day.jpg',
        '/middle.jpg',
        '/last.jpg',
      ]);
    });

    test(
      'filters unreadable photos while preserving chronological order',
      () async {
        final monday = DateTime(2026, 9, 28, 8);
        final meals = [
          _meal(monday, photoPath: '/unreadable.jpg'),
          _meal(
            monday.add(const Duration(minutes: 1)),
            photoPath: '/readable-1.jpg',
          ),
          _meal(
            monday.add(const Duration(minutes: 2)),
            photoPath: '/readable-2.jpg',
          ),
        ];

        final readable = await filterReadablePhotoMeals(meals, (meal) async {
          return meal.photoPath != '/unreadable.jpg';
        });

        expect(readable.map((meal) => meal.photoPath), [
          '/readable-1.jpg',
          '/readable-2.jpg',
        ]);
      },
    );

    test('signature changes when the week records change', () {
      final monday = DateTime(2026, 9, 28);
      final first = weeklyMealSignature([
        _meal(monday, kcal: 100, categoryId: FoodCategory.grains.id),
      ]);
      final second = weeklyMealSignature([
        _meal(monday, kcal: 100, categoryId: FoodCategory.grains.id),
        _meal(
          monday.add(const Duration(days: 1)),
          kcal: 200,
          categoryId: FoodCategory.grains.id,
        ),
      ]);

      expect(first, isNot(second));
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
