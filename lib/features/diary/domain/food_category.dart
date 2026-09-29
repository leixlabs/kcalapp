import 'food_item.dart';
import 'meal.dart';

enum FoodCategory {
  grains('grains', '🌾 谷 薯', 250),
  vegetablesAndFruits('vegetables_fruits', '🥬 蔬菜 水果', 650),
  meatEggsAndSeafood('meat_eggs_seafood', '🥩 肉 蛋 水产', 160),
  dairyBeansAndNuts('dairy_beans_nuts', '🥛 奶 豆 坚果', 340),
  other('other', '其他', 0);

  final String id;
  final String label;
  final double dailyReferenceGrams;

  const FoodCategory(this.id, this.label, this.dailyReferenceGrams);

  double get weeklyReferenceGrams => dailyReferenceGrams * 7;

  static FoodCategory? fromId(String? id) {
    if (id == 'dairy' || id == 'beans_nuts') {
      return dairyBeansAndNuts;
    }
    for (final category in values) {
      if (category.id == id) return category == other ? null : category;
    }
    return null;
  }

  static FoodCategory? classify(String name) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    if (_containsAny(normalized, _dairyKeywords) ||
        _containsAny(normalized, _beansAndNutsKeywords)) {
      return dairyBeansAndNuts;
    }
    if (_containsAny(normalized, _meatEggsAndSeafoodKeywords)) {
      return meatEggsAndSeafood;
    }
    if (_containsAny(normalized, _fruitKeywords)) return vegetablesAndFruits;
    if (_containsAny(normalized, _vegetableKeywords)) {
      return vegetablesAndFruits;
    }
    if (_containsAny(normalized, _grainsKeywords)) return grains;
    return null;
  }

  static bool _containsAny(String value, List<String> keywords) =>
      keywords.any(value.contains);

  static const _dairyKeywords = [
    '牛奶',
    '酸奶',
    '优酪乳',
    '奶酪',
    '芝士',
    '奶粉',
    '乳酪',
    '炼乳',
    'milk',
    'yogurt',
    'cheese',
  ];

  static const _beansAndNutsKeywords = [
    '豆腐',
    '豆浆',
    '豆干',
    '豆皮',
    '腐竹',
    '黄豆',
    '黑豆',
    '毛豆',
    '花生',
    '核桃',
    '杏仁',
    '腰果',
    '开心果',
    '榛子',
    '松子',
    '瓜子',
    '芝麻',
    'tofu',
    'soy',
    'walnut',
    'almond',
    'peanut',
  ];

  static const _meatEggsAndSeafoodKeywords = [
    '鸡蛋',
    '鸭蛋',
    '鹌鹑蛋',
    '蛋白',
    '蛋黄',
    '鸡肉',
    '鸡胸',
    '鸡腿',
    '鸭肉',
    '牛肉',
    '猪肉',
    '羊肉',
    '肉末',
    '排骨',
    '火腿',
    '培根',
    '香肠',
    '鱼',
    '虾',
    '蟹',
    '贝',
    '鱿鱼',
    '章鱼',
    '牡蛎',
    '扇贝',
    '三文鱼',
    '鳕鱼',
    'egg',
    'chicken',
    'beef',
    'pork',
    'fish',
    'shrimp',
  ];

  static const _fruitKeywords = [
    '苹果',
    '香蕉',
    '橙',
    '橘',
    '柚',
    '柠檬',
    '梨',
    '桃',
    '李子',
    '葡萄',
    '草莓',
    '蓝莓',
    '树莓',
    '猕猴桃',
    '奇异果',
    '西瓜',
    '哈密瓜',
    '甜瓜',
    '芒果',
    '菠萝',
    '凤梨',
    '樱桃',
    '车厘子',
    '荔枝',
    '龙眼',
    '火龙果',
    '榴莲',
    '木瓜',
    '枣',
    '牛油果',
    'apple',
    'banana',
    'orange',
    'grape',
    'strawberry',
  ];

  static const _vegetableKeywords = [
    '白菜',
    '青菜',
    '菠菜',
    '生菜',
    '西兰花',
    '花菜',
    '菜花',
    '番茄',
    '西红柿',
    '黄瓜',
    '胡萝卜',
    '萝卜',
    '茄子',
    '青椒',
    '辣椒',
    '洋葱',
    '香菇',
    '蘑菇',
    '木耳',
    '冬瓜',
    '南瓜',
    '芹菜',
    '豆角',
    '莴笋',
    '芦笋',
    '莲藕',
    '海带',
    '紫菜',
    '韭菜',
    '空心菜',
    '油麦菜',
    '卷心菜',
    '包菜',
    '甘蓝',
    'cabbage',
    'broccoli',
    'tomato',
    'cucumber',
    'carrot',
  ];

  static const _grainsKeywords = [
    '红豆',
    '绿豆',
    '鹰嘴豆',
    '米饭',
    '糙米',
    '大米',
    '小米',
    '米粥',
    '粥',
    '面条',
    '挂面',
    '馒头',
    '包子',
    '面包',
    '燕麦',
    '麦片',
    '玉米',
    '红薯',
    '地瓜',
    '土豆',
    '马铃薯',
    '山药',
    '芋头',
    '荞麦',
    '全麦',
    '藜麦',
    '杂粮',
    '粉条',
    '饺子',
    '馄饨',
    '栗子',
    'rice',
    'redbean',
    'mungbean',
    'chickpea',
    'oat',
    'bread',
    'noodle',
    'potato',
    'sweetpotato',
    'corn',
  ];
}

Map<FoodCategory, double> aggregateWeeklyFoodCategories(Iterable<Meal> meals) {
  final totals = {
    for (final category in FoodCategory.values.where(
      (category) => category != FoodCategory.other,
    ))
      category: 0.0,
  };
  for (final meal in meals) {
    for (final FoodItem item in meal.foodItems) {
      final category =
          FoodCategory.fromId(item.categoryId) ??
          FoodCategory.classify(item.name);
      if (category != null) {
        totals[category] = totals[category]! + item.weightG * meal.servings;
      }
    }
  }
  return totals;
}
