import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diary/presentation/home/home_page.dart';
import '../features/diary/presentation/meal_view/meal_view_page.dart';
import '../features/food_recognition/presentation/recognition_result_page.dart';
import '../features/goals/presentation/goal_settings_page.dart';
import '../features/llm_settings/presentation/llm_settings_page.dart';
import '../features/data_transfer/presentation/lan_api_page.dart';
import '../features/diary/presentation/weekly_summary/weekly_summary_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/weekly-summary',
        builder: (context, state) => WeeklySummaryPage(
          selectedDate: state.extra as DateTime? ?? DateTime.now(),
        ),
      ),
      GoRoute(
        path: '/meal-view',
        builder: (context, state) {
          final mealId = state.uri.queryParameters['id'];
          return MealViewPage(mealId: mealId);
        },
      ),
      GoRoute(
        path: '/recognition-result',
        builder: (context, state) => const RecognitionResultPage(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalSettingsPage(),
      ),
      GoRoute(
        path: '/llm-settings',
        builder: (context, state) => const LlmSettingsPage(),
      ),
      GoRoute(
        path: '/lan-api',
        builder: (context, state) => const LanApiPage(),
      ),
    ],
  );
});
