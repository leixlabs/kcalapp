class Nutrition {
  final double kcal;
  final double carbsG;
  final double proteinG;
  final double fatG;

  const Nutrition({
    required this.kcal,
    required this.carbsG,
    required this.proteinG,
    required this.fatG,
  });

  static const Nutrition zero = Nutrition(kcal: 0, carbsG: 0, proteinG: 0, fatG: 0);

  static Nutrition? tryParse({
    required double? kcal,
    required double? carbsG,
    required double? proteinG,
    required double? fatG,
  }) {
    final values = [kcal, carbsG, proteinG, fatG];
    if (values.any((v) => v == null || v.isNaN || v.isInfinite || v < 0)) {
      return null;
    }
    return Nutrition(kcal: kcal!, carbsG: carbsG!, proteinG: proteinG!, fatG: fatG!);
  }

  Nutrition operator +(Nutrition other) => Nutrition(
        kcal: kcal + other.kcal,
        carbsG: carbsG + other.carbsG,
        proteinG: proteinG + other.proteinG,
        fatG: fatG + other.fatG,
      );

  Nutrition operator *(double factor) => Nutrition(
        kcal: kcal * factor,
        carbsG: carbsG * factor,
        proteinG: proteinG * factor,
        fatG: fatG * factor,
      );

  Nutrition scaledByServings(double servings) => this * servings;

  String get kcalDisplay => kcal.round().toString();
  String get carbsDisplay => _formatGrams(carbsG);
  String get proteinDisplay => _formatGrams(proteinG);
  String get fatDisplay => _formatGrams(fatG);

  static String _formatGrams(double g) {
    return g.toStringAsFixed(g == g.roundToDouble() ? 0 : 1);
  }

  @override
  String toString() => 'Nutrition(kcal: $kcalDisplay, carbs: $carbsDisplay, protein: $proteinDisplay, fat: $fatDisplay)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nutrition &&
          kcal == other.kcal &&
          carbsG == other.carbsG &&
          proteinG == other.proteinG &&
          fatG == other.fatG;

  @override
  int get hashCode => Object.hash(kcal, carbsG, proteinG, fatG);
}
