import 'package:flutter_test/flutter_test.dart';
import 'package:calory/features/diary/domain/nutrition.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';

void main() {
  group('Nutrition', () {
    test('zero should have all values at 0', () {
      expect(Nutrition.zero.kcal, 0);
      expect(Nutrition.zero.carbsG, 0);
      expect(Nutrition.zero.proteinG, 0);
      expect(Nutrition.zero.fatG, 0);
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
