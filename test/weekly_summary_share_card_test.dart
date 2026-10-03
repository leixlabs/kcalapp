import 'dart:io';

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

      expect(find.text('本周饮食回顾'), findsOneWidget);
      expect(find.text('生成自 kcalapp'), findsOneWidget);

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

    testWidgets('skips unreadable photos before applying the tile limit', (
      tester,
    ) async {
      final directory = await Directory.systemTemp.createTemp(
        'weekly-summary-photos-',
      );
      addTearDown(() => directory.delete(recursive: true));
      const pngBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0x00,
        0x00,
        0x00,
        0x0d,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1f,
        0x15,
        0xc4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0b,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9c,
        0x63,
        0x60,
        0x00,
        0x02,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0xa5,
        0xf6,
        0x45,
        0x40,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4e,
        0x44,
        0xae,
        0x42,
        0x60,
        0x82,
      ];
      final readablePaths = <String>[];
      for (var i = 0; i < 10; i++) {
        final file = File('${directory.path}/photo-$i.png');
        await file.writeAsBytes(pngBytes);
        readablePaths.add(file.path);
      }

      final monday = DateTime(2026, 9, 28);
      final summary = WeeklySummary(
        weekStart: monday,
        meals: [
          _meal(monday, photoPath: '${directory.path}/missing.png'),
          for (var i = 0; i < readablePaths.length; i++)
            _meal(
              monday.add(Duration(minutes: i + 1)),
              photoPath: readablePaths[i],
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
                  happened: '一句锐评。',
                  improvement: '一句建议。',
                  dailyKcalGoal: 1800,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 十张可读照片中展示九张，最后一格提示剩余一张；坏路径不占名额。
      expect(find.byType(Image), findsNWidgets(9));
      expect(find.text('+1'), findsOneWidget);
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
