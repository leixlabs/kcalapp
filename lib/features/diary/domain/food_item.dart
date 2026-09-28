import 'nutrition.dart';

enum Confidence { low, medium, high }

class FoodItem {
  final int? id;
  final int? mealId;
  final String name;
  final double weightG;
  final double kcal;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final Confidence? confidence;
  final int sortOrder;

  const FoodItem({
    this.id,
    this.mealId,
    required this.name,
    required this.weightG,
    required this.kcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.confidence,
    this.sortOrder = 0,
  });

  Nutrition get nutrition => Nutrition(
        kcal: kcal,
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
      );

  FoodItem copyWith({
    int? id,
    int? mealId,
    String? name,
    double? weightG,
    double? kcal,
    double? carbsG,
    double? proteinG,
    double? fatG,
    Confidence? confidence,
    int? sortOrder,
  }) {
    return FoodItem(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      weightG: weightG ?? this.weightG,
      kcal: kcal ?? this.kcal,
      carbsG: carbsG ?? this.carbsG,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      confidence: confidence ?? this.confidence,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static Confidence? parseConfidence(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'low':
        return Confidence.low;
      case 'medium':
        return Confidence.medium;
      case 'high':
        return Confidence.high;
      default:
        return null;
    }
  }

  @override
  String toString() => 'FoodItem(name: $name, ${weightG}g, ${kcal.round()}kcal)';
}
