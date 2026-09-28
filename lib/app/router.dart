import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/diary/presentation/home/home_page.dart';
import '../features/diary/presentation/calendar/calendar_page.dart';
import '../features/diary/presentation/meal_editor/meal_editor_page.dart';
import '../features/food_recognition/presentation/recognition_result_page.dart';
import '../features/goals/presentation/goal_settings_page.dart';
import '../features/llm_settings/presentation/llm_settings_page.dart';
import '../features/data_transfer/presentation/export_page.dart';
import '../features/data_transfer/presentation/privacy_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/meal-editor',
        builder: (context, state) {
          final mealId = state.uri.queryParameters['id'];
          final dateStr = state.uri.queryParameters['date'];
          final mealTypeStr = state.uri.queryParameters['type'];
          return MealEditorPage(
            mealId: mealId,
            dateStr: dateStr,
            mealTypeStr: mealTypeStr,
          );
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
        path: '/export',
        builder: (context, state) => const ExportPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
    ],
  );
});
