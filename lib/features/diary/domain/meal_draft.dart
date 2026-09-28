import 'food_item.dart';
import 'meal_type.dart';

class MealDraft {
  final int? id;
  final String? photoTempPath;
  final String mealName;
  final MealType mealType;
  final double servings;
  final List<FoodItem> foodItems;
  final Confidence? overallConfidence;
  final String? notes;
  final String? rawResponse;

  const MealDraft({
    this.id,
    this.photoTempPath,
    required this.mealName,
    required this.mealType,
    this.servings = 1.0,
    this.foodItems = const [],
    this.overallConfidence,
    this.notes,
    this.rawResponse,
  });

  MealDraft copyWith({
    int? id,
    String? photoTempPath,
    String? mealName,
    MealType? mealType,
    double? servings,
    List<FoodItem>? foodItems,
    Confidence? overallConfidence,
    String? notes,
    String? rawResponse,
  }) {
    return MealDraft(
      id: id ?? this.id,
      photoTempPath: photoTempPath ?? this.photoTempPath,
      mealName: mealName ?? this.mealName,
      mealType: mealType ?? this.mealType,
      servings: servings ?? this.servings,
      foodItems: foodItems ?? this.foodItems,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      notes: notes ?? this.notes,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}
