import '../../../l10n/l10n.dart';
import 'food_category.dart';

/// [FoodCategory] 的本地化显示名（含 emoji）。
String foodCategoryName(AppLocalizations l10n, FoodCategory category) {
  switch (category) {
    case FoodCategory.grains:
      return l10n.foodCategoryGrains;
    case FoodCategory.vegetablesAndFruits:
      return l10n.foodCategoryVegetablesFruits;
    case FoodCategory.meatEggsAndSeafood:
      return l10n.foodCategoryMeatEggsSeafood;
    case FoodCategory.dairyBeansAndNuts:
      return l10n.foodCategoryDairyBeansNuts;
    case FoodCategory.other:
      return l10n.foodCategoryOther;
  }
}

/// [FoodCategory] 的纯文字名称（不含 emoji），用于周回顾文案。
String foodCategoryPlainName(AppLocalizations l10n, FoodCategory category) {
  switch (category) {
    case FoodCategory.grains:
      return l10n.weeklyCategoryPlainGrains;
    case FoodCategory.vegetablesAndFruits:
      return l10n.weeklyCategoryPlainVegetables;
    case FoodCategory.meatEggsAndSeafood:
      return l10n.weeklyCategoryPlainMeat;
    case FoodCategory.dairyBeansAndNuts:
      return l10n.weeklyCategoryPlainDairy;
    case FoodCategory.other:
      return l10n.foodCategoryOther;
  }
}
