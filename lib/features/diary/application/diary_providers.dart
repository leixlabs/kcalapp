import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'daily_summary.dart';
import '../domain/meal.dart';

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
