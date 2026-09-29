import 'micronutrients.dart';
import 'nutrition.dart';

export 'micronutrients.dart';

enum Confidence { low, medium, high }

class FoodItem {
  final int? id;
  final int? mealId;
  final String name;
  final String? categoryId;
  final double weightG;
  final double kcal;
  final double carbsG;
  final double proteinG;
  final double fatG;
  final Confidence? confidence;
  final int sortOrder;

  /// 微量矿物质（mg/μg），按 [Mineral] 枚举顺序，长度固定为 [Mineral.values.length]（8）。
  /// null 整体：无矿物质数据；元素 null：该矿物质未知；0：极微量/已估算为零。
  final List<double?>? minerals;

  /// 维生素（mg/μg），按 [Vitamin] 枚举顺序，长度固定为 [Vitamin.values.length]（13）。
  /// null 整体：无维生素数据；元素 null：该维生素未知；0：极微量/已估算为零。
  final List<double?>? vitamins;

  const FoodItem({
    this.id,
    this.mealId,
    required this.name,
    this.categoryId,
    required this.weightG,
    required this.kcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
    this.confidence,
    this.sortOrder = 0,
    this.minerals,
    this.vitamins,
  });

  Nutrition get nutrition =>
      Nutrition(kcal: kcal, carbsG: carbsG, proteinG: proteinG, fatG: fatG);

  /// 获取指定矿物质的值（mg/μg），null 表示未知。
  double? getMineral(Mineral m) => minerals?[m.index];

  /// 获取指定维生素的值（mg/μg），null 表示未知。
  double? getVitamin(Vitamin v) => vitamins?[v.index];

  FoodItem copyWith({
    int? id,
    int? mealId,
    String? name,
    String? categoryId,
    double? weightG,
    double? kcal,
    double? carbsG,
    double? proteinG,
    double? fatG,
    Confidence? confidence,
    int? sortOrder,
    List<double?>? minerals,
    List<double?>? vitamins,
  }) {
    return FoodItem(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      weightG: weightG ?? this.weightG,
      kcal: kcal ?? this.kcal,
      carbsG: carbsG ?? this.carbsG,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      confidence: confidence ?? this.confidence,
      sortOrder: sortOrder ?? this.sortOrder,
      minerals: minerals ?? this.minerals,
      vitamins: vitamins ?? this.vitamins,
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
  String toString() =>
      'FoodItem(name: $name, ${weightG}g, ${kcal.round()}kcal)';
}
