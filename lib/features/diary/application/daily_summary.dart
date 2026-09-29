import '../domain/daily_goal.dart';
import '../domain/nutrition.dart';
import '../domain/meal.dart';
import '../domain/meal_type.dart';

Map<DateTime, double> aggregateDailyKcal(Iterable<Meal> meals) {
  final totals = <DateTime, double>{};
  for (final meal in meals) {
    final date = DateTime(
      meal.dateTime.year,
      meal.dateTime.month,
      meal.dateTime.day,
    );
    totals[date] = (totals[date] ?? 0) + meal.totalNutrition.kcal;
  }
  return totals;
}

class DailySummary {
  final DateTime date;
  final List<Meal> meals;
  final DailyGoal? goal;

  DailySummary({required this.date, required this.meals, this.goal});

  Nutrition get consumed {
    if (meals.isEmpty) return Nutrition.zero;
    var total = Nutrition.zero;
    for (final meal in meals) {
      total = total + meal.totalNutrition;
    }
    return total;
  }

  Nutrition? get target => goal?.target;

  Nutrition? get remaining {
    if (target == null) return null;
    return Nutrition(
      kcal: target!.kcal - consumed.kcal,
      carbsG: target!.carbsG - consumed.carbsG,
      proteinG: target!.proteinG - consumed.proteinG,
      fatG: target!.fatG - consumed.fatG,
    );
  }

  double get kcalProgress {
    if (target == null || target!.kcal == 0) return 0;
    final progress = consumed.kcal / target!.kcal;
    return progress.clamp(0.0, 1.0);
  }

  double get rawKcalProgress {
    if (target == null || target!.kcal == 0) return 0;
    return consumed.kcal / target!.kcal;
  }

  bool get isOverGoal {
    if (target == null) return false;
    return consumed.kcal > target!.kcal;
  }

  double _macroProgress(double consumed, double? target) {
    if (target == null || target == 0) return 0;
    return (consumed / target).clamp(0.0, 1.0);
  }

  double get carbsProgress => _macroProgress(consumed.carbsG, target?.carbsG);
  double get proteinProgress =>
      _macroProgress(consumed.proteinG, target?.proteinG);
  double get fatProgress => _macroProgress(consumed.fatG, target?.fatG);

  List<Meal> mealsByType(MealType type) =>
      meals.where((m) => m.mealType == type).toList();
}
