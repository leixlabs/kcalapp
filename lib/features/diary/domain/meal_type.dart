import 'package:flutter/material.dart';

enum MealType {
  breakfast('早餐'),
  lunch('午餐'),
  dinner('晚餐'),
  snack('加餐');

  const MealType(this.label);
  final String label;

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

  static MealType? fromLabel(String label) {
    for (final t in MealType.values) {
      if (t.label == label) return t;
    }
    return null;
  }

  static MealType guessFromHour(int hour) {
    if (hour >= 5 && hour < 10) return MealType.breakfast;
    if (hour >= 10 && hour < 14) return MealType.lunch;
    if (hour >= 17 && hour < 21) return MealType.dinner;
    return MealType.snack;
  }
}
