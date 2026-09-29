import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:calory/features/diary/domain/nutrition.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';
import 'package:calory/features/diary/domain/daily_goal.dart';
import 'package:calory/features/diary/domain/food_category.dart';
import 'package:calory/features/diary/application/daily_summary.dart';
import 'package:calory/core/widgets/ruler_value_picker.dart';
import 'package:calory/data/llm/llm_schema.dart';
import 'package:calory/features/diary/presentation/home/widgets/meal_section.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Nutrition', () {
    test('zero should have all values at 0', () {
      expect(Nutrition.zero.kcal, 0);
      expect(Nutrition.zero.carbsG, 0);
      expect(Nutrition.zero.proteinG, 0);
      expect(Nutrition.zero.fatG, 0);
    });

    group('RulerValuePicker', () {
      testWidgets('a single tick drag changes the value by one step', (
        tester,
      ) async {
        final values = <double>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RulerValuePicker(
                value: 16.9,
                max: 100,
                step: 0.1,
                unit: 'g',
                color: Colors.teal,
                onChanged: values.add,
              ),
            ),
          ),
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText && widget.text.toPlainText() == '16.9 g',
          ),
          findsOneWidget,
        );
        await tester.drag(find.byType(ListView), const Offset(-12, 0));
        await tester.pumpAndSettle();

        expect(values, [17.0]);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText && widget.text.toPlainText() == '17.0 g',
          ),
          findsOneWidget,
        );
      });
    });

    test('addition should sum all values', () {
      final a = Nutrition(kcal: 100, carbsG: 10, proteinG: 5, fatG: 3);
      final b = Nutrition(kcal: 200, carbsG: 20, proteinG: 10, fatG: 7);
      final sum = a + b;
      expect(sum.kcal, 300);
      expect(sum.carbsG, 30);
      expect(sum.proteinG, 15);
      expect(sum.fatG, 10);
    });

    test('scaling by servings should multiply all values', () {
      final n = Nutrition(kcal: 100, carbsG: 10, proteinG: 5, fatG: 3);
      final scaled = n.scaledByServings(2);
      expect(scaled.kcal, 200);
      expect(scaled.carbsG, 20);
      expect(scaled.proteinG, 10);
      expect(scaled.fatG, 6);
    });

    test('tryParse should reject negative values', () {
      expect(
        Nutrition.tryParse(kcal: -1, carbsG: 0, proteinG: 0, fatG: 0),
        isNull,
      );
    });

    test('tryParse should reject NaN', () {
      expect(
        Nutrition.tryParse(kcal: double.nan, carbsG: 0, proteinG: 0, fatG: 0),
        isNull,
      );
    });

    test('display formatting should round kcal and format grams', () {
      final n = Nutrition(
        kcal: 462.7,
        carbsG: 43.0,
        proteinG: 17.2,
        fatG: 20.25,
      );
      expect(n.kcalDisplay, '463');
      expect(n.carbsDisplay, '43');
      expect(n.proteinDisplay, '17.2');
    });
  });

  group('Meal', () {
    test('copyWith preserves AI recognition status', () {
      final meal = Meal(
        dateTime: DateTime(2026, 9, 29),
        mealType: MealType.dinner,
        name: 'Recognition',
        aiRecognitionStatus: AiRecognitionStatus.failed,
        createdAt: DateTime(2026, 9, 29),
        updatedAt: DateTime(2026, 9, 29),
      );

      expect(
        meal.copyWith(name: 'Retry').aiRecognitionStatus,
        AiRecognitionStatus.failed,
      );
      expect(
        meal
            .copyWith(aiRecognitionStatus: AiRecognitionStatus.processing)
            .aiRecognitionStatus,
        AiRecognitionStatus.processing,
      );
    });

    test('total nutrition should aggregate from food items', () {
      final meal = Meal(
        dateTime: DateTime.now(),
        mealType: MealType.breakfast,
        name: 'Test meal',
        foodItems: [
          FoodItem(
            name: 'Rice',
            weightG: 200,
            kcal: 260,
            carbsG: 56,
            proteinG: 5,
            fatG: 1,
          ),
          FoodItem(
            name: 'Egg',
            weightG: 50,
            kcal: 78,
            carbsG: 0.6,
            proteinG: 6.3,
            fatG: 5.3,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(meal.totalNutrition.kcal, 338);
      expect(meal.totalNutrition.carbsG, 56.6);
      expect(meal.totalNutrition.proteinG, 11.3);
      expect(meal.totalNutrition.fatG, 6.3);
    });

    test('empty meal should have zero nutrition', () {
      final meal = Meal(
        dateTime: DateTime.now(),
        mealType: MealType.lunch,
        name: 'Empty',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(meal.totalNutrition.kcal, 0);
    });

    test('copyWith preserves nutritionist review', () {
      final meal = Meal(
        dateTime: DateTime.now(),
        mealType: MealType.lunch,
        name: 'Lunch',
        nutritionReview: '均衡营养，适量食用。',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        meal.copyWith(name: 'Updated lunch').nutritionReview,
        '均衡营养，适量食用。',
      );
    });

    test('servings should scale total nutrition', () {
      final meal = Meal(
        dateTime: DateTime.now(),
        mealType: MealType.dinner,
        name: 'Dinner',
        servings: 2,
        foodItems: [
          FoodItem(
            name: 'Chicken',
            weightG: 100,
            kcal: 165,
            carbsG: 0,
            proteinG: 31,
            fatG: 3.6,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(meal.totalNutrition.kcal, 330);
      expect(meal.totalNutrition.proteinG, 62);
    });

    test('total weight should sum food item weights', () {
      final meal = Meal(
        dateTime: DateTime.now(),
        mealType: MealType.snack,
        name: 'Snack',
        foodItems: [
          FoodItem(
            name: 'Cookie',
            weightG: 30,
            kcal: 150,
            carbsG: 20,
            proteinG: 2,
            fatG: 7,
          ),
          FoodItem(
            name: 'Milk',
            weightG: 200,
            kcal: 120,
            carbsG: 12,
            proteinG: 8,
            fatG: 5,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(meal.totalWeightG, 230);
    });

    test(
      'daily kcal aggregation distinguishes same day number across months',
      () {
        final now = DateTime.now();
        Meal mealFor(DateTime date, double kcal) => Meal(
          dateTime: date,
          mealType: MealType.lunch,
          name: 'Meal',
          foodItems: [
            FoodItem(
              name: 'Food',
              weightG: 100,
              kcal: kcal,
              carbsG: 0,
              proteinG: 0,
              fatG: 0,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final totals = aggregateDailyKcal([
          mealFor(DateTime(2026, 9, 1, 8), 120),
          mealFor(DateTime(2026, 9, 1, 12), 80),
          mealFor(DateTime(2026, 8, 1, 8), 200),
        ]);

        expect(totals[DateTime(2026, 9, 1)], 200);
        expect(totals[DateTime(2026, 8, 1)], 200);
        expect(totals, hasLength(2));
      },
    );
  });

  group('DailyGoal defaults', () {
    test('uses the personalized daily calorie and macro targets', () {
      final goal = DailyGoal.recommendedDefaults;

      expect(goal.kcal, 1870);
      expect(goal.carbsG, 257);
      expect(goal.proteinG, 84);
      expect(goal.fatG, 56);
    });
  });

  testWidgets('double-tapping a failed meal photo requests a retry', (
    tester,
  ) async {
    final date = DateTime(2026, 9, 29);
    final meal = Meal(
      dateTime: date,
      mealType: MealType.dinner,
      name: '识别失败的餐食',
      aiRecognitionStatus: AiRecognitionStatus.failed,
      createdAt: date,
      updatedAt: date,
    );
    var retryCount = 0;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: MealSection(
              mealType: MealType.dinner,
              meals: [meal],
              selectedDate: date,
              onRetryRecognition: (_) => retryCount++,
            ),
          ),
        ),
        GoRoute(
          path: '/meal-view',
          builder: (context, state) =>
              const Scaffold(body: Text('Meal detail')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final photoCenter = tester.getCenter(find.byIcon(Icons.restaurant));

    await tester.tapAt(photoCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(photoCenter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(retryCount, 1);
    expect(find.text('Meal detail'), findsNothing);
    router.dispose();
  });

  group('FoodCategory', () {
    test('classifies common food names into broad guideline groups', () {
      expect(FoodCategory.classify('糙米饭'), FoodCategory.grains);
      expect(FoodCategory.classify('红豆'), FoodCategory.grains);
      expect(FoodCategory.classify('西兰花'), FoodCategory.vegetablesAndFruits);
      expect(FoodCategory.classify('苹果'), FoodCategory.vegetablesAndFruits);
      expect(FoodCategory.classify('鸡蛋'), FoodCategory.meatEggsAndSeafood);
      expect(FoodCategory.classify('牛奶'), FoodCategory.dairyBeansAndNuts);
      expect(FoodCategory.classify('豆腐'), FoodCategory.dairyBeansAndNuts);
      expect(FoodCategory.classify('核桃'), FoodCategory.dairyBeansAndNuts);
      expect(FoodCategory.classify('咖啡'), isNull);
      expect(
        FoodCategory.values.where((category) => category != FoodCategory.other),
        [
          FoodCategory.grains,
          FoodCategory.vegetablesAndFruits,
          FoodCategory.meatEggsAndSeafood,
          FoodCategory.dairyBeansAndNuts,
        ],
      );
      expect(FoodCategory.fromId('dairy'), FoodCategory.dairyBeansAndNuts);
      expect(FoodCategory.fromId('beans_nuts'), FoodCategory.dairyBeansAndNuts);
    });

    test(
      'weekly category totals include servings and ignore unknown foods',
      () {
        final date = DateTime(2026, 9, 29);
        final totals = aggregateWeeklyFoodCategories([
          Meal(
            dateTime: date,
            mealType: MealType.breakfast,
            name: '早餐',
            servings: 2,
            foodItems: [
              FoodItem(
                name: '燕麦',
                weightG: 40,
                kcal: 150,
                carbsG: 25,
                proteinG: 5,
                fatG: 3,
              ),
              FoodItem(
                name: '咖啡',
                weightG: 200,
                kcal: 2,
                carbsG: 0,
                proteinG: 0,
                fatG: 0,
              ),
            ],
            createdAt: date,
            updatedAt: date,
          ),
        ]);

        expect(totals[FoodCategory.grains], 80);
        expect(totals.values.reduce((a, b) => a + b), 80);
      },
    );

    test('recognition schema retains model-assigned category ids', () {
      final result = LlmSchemaValidator.parse(
        jsonEncode({
          'meal_name': '测试餐',
          'items': [
            {
              'name': '海带',
              'category_id': 'vegetables_fruits',
              'weight_g': 50,
              'kcal': 10,
              'carbs_g': 2,
              'protein_g': 1,
              'fat_g': 0,
            },
            {
              'name': '不明食材',
              'category_id': 'other',
              'weight_g': 20,
              'kcal': 5,
              'carbs_g': 1,
              'protein_g': 0,
              'fat_g': 0,
            },
          ],
        }),
      );

      expect(result.foodItems[0].categoryId, 'vegetables_fruits');
      expect(result.foodItems[1].categoryId, isNull);
    });
  });

  group('MealType', () {
    test('guessFromHour should return correct type', () {
      expect(MealType.guessFromHour(7), MealType.breakfast);
      expect(MealType.guessFromHour(12), MealType.lunch);
      expect(MealType.guessFromHour(18), MealType.dinner);
      expect(MealType.guessFromHour(15), MealType.snack);
    });

    test('fromString should return correct type', () {
      expect(MealType.fromString('breakfast'), MealType.breakfast);
      expect(MealType.fromString('lunch'), MealType.lunch);
      expect(MealType.fromString('invalid'), MealType.breakfast);
    });

    test('labels should be in Chinese', () {
      expect(MealType.breakfast.label, '早餐');
      expect(MealType.lunch.label, '午餐');
      expect(MealType.dinner.label, '晚餐');
      expect(MealType.snack.label, '加餐');
    });
  });

  group('Micronutrients', () {
    test('mineral enum includes calcium, sodium, and magnesium', () {
      expect(Mineral.calcium.label, '钙');
      expect(Mineral.sodium.label, '钠');
      expect(Mineral.magnesium.label, '镁');
      expect(Mineral.calcium.unit, 'mg');
      expect(Mineral.sodium.unit, 'mg');
      expect(Mineral.magnesium.unit, 'mg');
    });

    test('legacy eight-mineral data remains readable', () {
      final values = MicronutrientList.fromJson(
        '[1,2,3,4,5,6,7,8]',
        length: Mineral.values.length,
      );

      expect(values, hasLength(Mineral.values.length));
      expect(values!.take(8).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(values.skip(8).toList(), [null, null, null]);
    });
  });
}
