import '../domain/food_category.dart';
import '../domain/meal.dart';

DateTime weekStartFor(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: date.weekday - 1));

/// 保持原顺序筛出可读取的照片记录，避免失效照片占用分享拼图名额。
Future<List<Meal>> filterReadablePhotoMeals(
  Iterable<Meal> meals,
  Future<bool> Function(Meal meal) isReadable,
) async {
  final readable = <Meal>[];
  for (final meal in meals) {
    if (await isReadable(meal)) readable.add(meal);
  }
  return readable;
}

/// 该周饮食记录的指纹：天数、食物项数、热量与总重量任一变化都会改变它，
/// 用于判断已持久化的周回顾是否过期。
String weeklyMealSignature(Iterable<Meal> meals) {
  var itemCount = 0;
  var kcal = 0.0;
  var grams = 0.0;
  var count = 0;
  for (final meal in meals) {
    count += 1;
    itemCount += meal.foodItems.length;
    kcal += meal.totalNutrition.kcal;
    grams += meal.totalWeightG;
  }
  return '$count:$itemCount:${kcal.round()}:${grams.round()}';
}

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

  static const Map<FoodCategory, String> _categoryPlainNames = {
    FoodCategory.grains: '谷薯类',
    FoodCategory.vegetablesAndFruits: '蔬菜水果',
    FoodCategory.meatEggsAndSeafood: '肉蛋水产',
    FoodCategory.dairyBeansAndNuts: '奶豆坚果',
  };

  /// 无 AI 时的兜底描述：仅陈述记录到的天数、日均与占比最高的类别。
  String get happenedSummary {
    if (meals.isEmpty) return '这一周还没有饮食记录。';
    final clauses = <String>['这一周记录了 $recordedDays 天'];
    final average = averageKcalOnEstimatedDays;
    if (average != null) clauses.add('日均约 ${average.round()} kcal');
    final grams = foodCategoryGrams;
    final present =
        _categoryPlainNames.keys
            .where((category) => (grams[category] ?? 0) > 0)
            .toList()
          ..sort((a, b) => (grams[b] ?? 0).compareTo(grams[a] ?? 0));
    if (present.isNotEmpty) {
      clauses.add('${_categoryPlainNames[present.first]}相对较多');
    }
    return '${clauses.join('，')}。';
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

  /// 本周所有带照片的记录，按时间先后排列。
  List<Meal> get photoMeals =>
      meals
          .where(
            (meal) =>
                (meal.photoAssetId != null && meal.photoAssetId!.isNotEmpty) ||
                (meal.photoPath != null && meal.photoPath!.isNotEmpty),
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
}
