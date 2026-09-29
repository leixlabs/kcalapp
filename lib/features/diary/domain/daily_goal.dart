import 'nutrition.dart';

class DailyGoal {
  final int? id;
  final DateTime effectiveDate;
  final double kcal;
  final double carbsG;
  final double proteinG;
  final double fatG;

  const DailyGoal({
    this.id,
    required this.effectiveDate,
    required this.kcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  Nutrition get target =>
      Nutrition(kcal: kcal, carbsG: carbsG, proteinG: proteinG, fatG: fatG);

  static const _recommendedKcal = 1870.0;
  static const _recommendedCarbs = 257.0;
  static const _recommendedProtein = 84.0;
  static const _recommendedFat = 56.0;

  static double get recommendedKcal => _recommendedKcal;
  static double get recommendedCarbsG => _recommendedCarbs;
  static double get recommendedProteinG => _recommendedProtein;
  static double get recommendedFatG => _recommendedFat;

  static DailyGoal get recommendedDefaults => DailyGoal(
    id: null,
    effectiveDate: DateTime.now(),
    kcal: _recommendedKcal,
    carbsG: _recommendedCarbs,
    proteinG: _recommendedProtein,
    fatG: _recommendedFat,
  );

  DailyGoal copyWith({
    int? id,
    DateTime? effectiveDate,
    double? kcal,
    double? carbsG,
    double? proteinG,
    double? fatG,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      kcal: kcal ?? this.kcal,
      carbsG: carbsG ?? this.carbsG,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
    );
  }
}
