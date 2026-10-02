import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calory/features/diary/application/weekly_summary.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';
import 'package:calory/features/diary/presentation/weekly_summary/widgets/weekly_summary_share_card.dart';

// 1x1 透明 PNG
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  testWidgets('photo renders with non-zero size', (tester) async {
    final dir = Directory.systemTemp.createTempSync('repro');
    final file = File('${dir.path}/a.png');
    file.writeAsBytesSync(base64Decode(_png));

    final monday = DateTime(2026, 9, 28);
    final summary = WeeklySummary(
      weekStart: monday,
      meals: [
        _meal(monday, photoPath: file.path),
        _meal(monday.add(const Duration(days: 1)), photoPath: file.path),
        _meal(monday.add(const Duration(days: 2)), photoPath: file.path),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: WeeklySummaryShareCard(
                  summary: summary,
                  periodEnd: monday,
                  happened: 'a',
                  improvement: 'b',
                  dailyKcalGoal: 1800,
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await tester.pump();
      }
    });

    // ignore: avoid_print
    print('IMAGE WIDGETS: ${find.byType(Image).evaluate().length}');
    // ignore: avoid_print
    print('RAW IMAGES (decoded): ${find.byType(RawImage).evaluate().length}');
    // ignore: avoid_print
    print('PHOTO MEALS: ${summary.photoMeals.length}');
  });
}

Meal _meal(DateTime date, {String? photoPath}) => Meal(
  dateTime: date,
  mealType: MealType.lunch,
  name: '测试餐',
  photoPath: photoPath,
  foodItems: const [
    FoodItem(
      name: '测试食材',
      weightG: 100,
      kcal: 500,
      carbsG: 0,
      proteinG: 0,
      fatG: 0,
    ),
  ],
  createdAt: date,
  updatedAt: date,
);
