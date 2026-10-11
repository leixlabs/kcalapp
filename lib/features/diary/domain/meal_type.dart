import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.breakfast_dining;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.local_cafe;
    }
  }

  static MealType fromString(String? value) {
    return MealType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MealType.breakfast,
    );
  }

  static MealType guessFromHour(int hour) {
    if (hour >= 5 && hour < 10) return MealType.breakfast;
    if (hour >= 10 && hour < 14) return MealType.lunch;
    if (hour >= 17 && hour < 21) return MealType.dinner;
    return MealType.snack;
  }
}

/// [MealType] 的本地化显示名。
String mealTypeLabel(AppLocalizations l10n, MealType type) => switch (type) {
  MealType.breakfast => l10n.mealTypeBreakfast,
  MealType.lunch => l10n.mealTypeLunch,
  MealType.dinner => l10n.mealTypeDinner,
  MealType.snack => l10n.mealTypeSnack,
};
