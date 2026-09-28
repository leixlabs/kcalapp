import 'food_item.dart';
import 'nutrition.dart';
import 'meal_type.dart';

class Meal {
  final int? id;
  final DateTime dateTime;
  final MealType mealType;
  final String name;
  final String? photoPath;
  final double servings;
  final String source;
  final List<FoodItem> foodItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Meal({
    this.id,
    required this.dateTime,
    required this.mealType,
    required this.name,
    this.photoPath,
    this.servings = 1.0,
    this.source = 'manual',
    this.foodItems = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Nutrition get totalNutrition {
    if (foodItems.isEmpty) return Nutrition.zero;
    var total = Nutrition.zero;
    for (final item in foodItems) {
      total = total + item.nutrition;
    }
    return total.scaledByServings(servings);
  }

  double get totalWeightG {
    if (foodItems.isEmpty) return 0;
    return foodItems.fold(0.0, (sum, item) => sum + item.weightG) * servings;
  }

  Meal copyWith({
    int? id,
    DateTime? dateTime,
    MealType? mealType,
    String? name,
    String? photoPath,
    double? servings,
    String? source,
    List<FoodItem>? foodItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meal(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      servings: servings ?? this.servings,
      source: source ?? this.source,
      foodItems: foodItems ?? this.foodItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Meal($name, ${mealType.label}, ${foodItems.length} items, ${totalNutrition.kcalDisplay}kcal)';
}
