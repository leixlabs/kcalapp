import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calory/features/diary/application/weekly_summary.dart';
import 'package:calory/features/diary/domain/food_category.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';
import 'package:calory/features/diary/presentation/weekly_summary/widgets/weekly_summary_share_card.dart';

void main() {
  group('WeeklySummaryShareCard', () {
    testWidgets('renders the sections in the expected order', (tester) async {
      final monday = DateTime(2026, 9, 28, 8);
      final summary = WeeklySummary(
        weekStart: DateTime(2026, 9, 28),
        meals: [
          _meal(monday, kcal: 800, categoryId: FoodCategory.grains.id),
          _meal(
            monday.add(const Duration(days: 1)),
            kcal: 900,
            categoryId: FoodCategory.vegetablesAndFruits.id,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: WeeklySummaryShareCard(
                  summary: summary,
                  periodEnd: monday.add(const Duration(days: 6)),
                  happened: '这一周吃得还挺规律。',
                  improvement: '下周多加一份蔬菜。',
                  dailyKcalGoal: 1800,
                ),
              ),
            ),
          ),
        ),
      );

      // 汇总：仅保留日均，不再展示记录天数。
      expect(find.text('已估算日均'), findsOneWidget);
      expect(find.textContaining('有记录'), findsNothing);

      // 热力图图例。
      expect(find.text('每日达成'), findsOneWidget);
      expect(find.text('未记录'), findsOneWidget);
      expect(find.text('达标'), findsOneWidget);

      // 进度组件复用、锐评与建议。
      expect(find.text('食物类别 · 本周'), findsOneWidget);
      expect(find.text('🥬 蔬菜 水果'), findsOneWidget);
      expect(find.text('本周锐评'), findsOneWidget);
      expect(find.text('饮食建议'), findsOneWidget);

      // 无照片时不使用占位图。
      expect(find.byIcon(Icons.restaurant_outlined), findsNothing);
    });

    testWidgets('hides the photo area entirely when there are no photos', (
      tester,
    ) async {
      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [_meal(monday, kcal: 500)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: WeeklySummaryShareCard(
                  summary: summary,
                  periodEnd: monday.add(const Duration(days: 6)),
                  happened: '一句锐评。',
                  improvement: '一句建议。',
                  dailyKcalGoal: 1800,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.text('已估算日均'), findsOneWidget);
    });
  });
}

Meal _meal(
  DateTime date, {
  double kcal = 0,
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
              weightG: 100,
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
