import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'daily_summary.dart';
import 'weekly_summary.dart';
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

final weeklyMealsProvider = FutureProvider.family<List<Meal>, DateTime>((
  ref,
  selectedDate,
) {
  final weekStart = weekStartFor(selectedDate);
  final nextMonday = weekStart.add(const Duration(days: 7));
  return ref
      .watch(mealRepositoryProvider)
      .getMealsBetween(weekStart, nextMonday);
});

final weeklyFoodCategoryProgressProvider =
    FutureProvider.family<Map<FoodCategory, double>, DateTime>((
      ref,
      selectedDate,
    ) async {
      final meals = await ref.watch(weeklyMealsProvider(selectedDate).future);
      return aggregateWeeklyFoodCategories(meals);
    });

/// 本周每日总热量，用于首页周日期条。
final weeklyKcalProvider =
    FutureProvider.family<Map<DateTime, double>, DateTime>((
      ref,
      selectedDate,
    ) async {
      final meals = await ref.watch(weeklyMealsProvider(selectedDate).future);
      return aggregateDailyKcal(meals);
    });

/// 评价按「日期 + 餐次」归类。key 统一归一化到当天零点，避免同一餐次因
/// 传入的 `DateTime` 携带时分秒不同而生成多个缓存实例，导致失效通知打不中
/// 正在被 UI 监听的实例。
typedef MealReviewKey = ({DateTime date, MealType mealType});

MealReviewKey mealReviewKey(DateTime date, MealType mealType) =>
    (date: DateTime(date.year, date.month, date.day), mealType: mealType);

final mealReviewProvider = FutureProvider.family<MealReview?, MealReviewKey>((
  ref,
  key,
) {
  return ref.watch(mealReviewDaoProvider).get(key.date, key.mealType);
});
