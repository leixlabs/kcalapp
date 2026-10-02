import '../domain/food_category.dart';
import '../domain/meal.dart';

DateTime weekStartFor(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: date.weekday - 1));

class WeeklySummary {
  final DateTime weekStart;
  final List<Meal> meals;

  const WeeklySummary({required this.weekStart, required this.meals});

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  int get recordedDays => meals
      .map(
        (meal) => DateTime(
          meal.dateTime.year,
          meal.dateTime.month,
          meal.dateTime.day,
        ),
      )
      .toSet()
      .length;

  Map<DateTime, double> get dailyKcal {
    final totals = <DateTime, double>{};
    for (final meal in meals) {
      final kcal = meal.totalNutrition.kcal;
      if (kcal <= 0) continue;
      final day = DateTime(
        meal.dateTime.year,
        meal.dateTime.month,
        meal.dateTime.day,
      );
      totals[day] = (totals[day] ?? 0) + kcal;
    }
    return totals;
  }

  double? get averageKcalOnEstimatedDays {
    final totals = dailyKcal.values;
    if (totals.isEmpty) return null;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  Map<FoodCategory, double> get foodCategoryGrams =>
      aggregateWeeklyFoodCategories(meals);

  FoodCategory? get focusCategory {
    if (recordedDays < 3) return null;
    final grams = foodCategoryGrams;
    final categories = FoodCategory.values.where(
      (category) => category != FoodCategory.other,
    );
    if (categories.every((category) => grams[category] == 0)) return null;

    return categories.reduce((a, b) {
      final aProgress = grams[a]! / a.weeklyReferenceGrams;
      final bProgress = grams[b]! / b.weeklyReferenceGrams;
      return aProgress <= bProgress ? a : b;
    });
  }

  String get nextWeekFocus {
    final category = focusCategory;
    if (category == null) {
      return '继续记录不同餐次，让下周回顾更贴近你的饮食。';
    }
    return switch (category) {
      FoodCategory.grains => '下周可以留意谷薯类主食的安排。',
      FoodCategory.vegetablesAndFruits => '下周试着在午餐或晚餐加一份蔬菜。',
      FoodCategory.meatEggsAndSeafood => '下周可以留意肉、蛋或水产的搭配。',
      FoodCategory.dairyBeansAndNuts => '下周可以留意奶、豆或坚果的搭配。',
      FoodCategory.other => '继续记录不同餐次，让下周回顾更贴近你的饮食。',
    };
  }

  /// Selects up to three real meal photos from different days across the week.
  List<Meal> get photoMeals {
    final firstPhotoByDay = <DateTime, Meal>{};
    for (final meal in meals) {
      if (meal.photoPath == null || meal.photoPath!.isEmpty) continue;
      final day = DateTime(
        meal.dateTime.year,
        meal.dateTime.month,
        meal.dateTime.day,
      );
      firstPhotoByDay.putIfAbsent(day, () => meal);
    }

    final candidates = firstPhotoByDay.values.toList();
    if (candidates.length <= 3) return candidates;
    return [
      candidates.first,
      candidates[candidates.length ~/ 2],
      candidates.last,
    ];
  }
}
