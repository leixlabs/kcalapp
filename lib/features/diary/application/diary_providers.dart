import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'daily_summary.dart';
import '../domain/meal.dart';
import '../domain/food_category.dart';
import '../domain/meal_review.dart';
import '../domain/meal_type.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailySummaryProvider = FutureProvider<DailySummary>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final mealRepo = ref.watch(mealRepositoryProvider);
  final goalRepo = ref.watch(goalRepositoryProvider);

  final meals = await mealRepo.getMealsByDate(date);
  final goal = await goalRepo.getGoalForDate(date);

  return DailySummary(date: date, meals: meals, goal: goal);
});

final mealsByDateProvider = FutureProvider.family<List<Meal>, DateTime>((
  ref,
  date,
) async {
  final mealRepo = ref.watch(mealRepositoryProvider);
  return mealRepo.getMealsByDate(date);
});

final monthlyMealsProvider =
    FutureProvider.family<Map<DateTime, double>, DateTime>((ref, month) async {
      final mealRepo = ref.watch(mealRepositoryProvider);
      final meals = await mealRepo.getMealsByMonth(month);
      return aggregateDailyKcal(meals);
    });

final weeklyFoodCategoryProgressProvider =
    FutureProvider.family<Map<FoodCategory, double>, DateTime>((
      ref,
      selectedDate,
    ) async {
      final monday = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ).subtract(Duration(days: selectedDate.weekday - 1));
      final nextMonday = monday.add(const Duration(days: 7));
      final mealRepo = ref.watch(mealRepositoryProvider);
      final meals = await mealRepo.getMealsBetween(monday, nextMonday);
      return aggregateWeeklyFoodCategories(meals);
    });

final mealReviewProvider =
    FutureProvider.family<MealReview?, ({DateTime date, MealType mealType})>((
      ref,
      key,
    ) {
      return ref.watch(mealReviewDaoProvider).get(key.date, key.mealType);
    });
