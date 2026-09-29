import 'dart:convert';
import '../../features/diary/domain/food_item.dart';
import '../../features/diary/domain/meal_draft.dart';
import '../../features/diary/domain/meal_type.dart';

class LlmRecognitionResult {
  final String mealName;
  final List<FoodItem> foodItems;
  final Confidence? overallConfidence;
  final String? notes;
  final String? rawResponse;

  LlmRecognitionResult({
    required this.mealName,
    required this.foodItems,
    this.overallConfidence,
    this.notes,
    this.rawResponse,
  });
}

class LlmSchemaException implements Exception {
  final String message;
  LlmSchemaException(this.message);
  @override
  String toString() => '识别结果解析失败: $message';
}

class LlmSchemaValidator {
  static LlmRecognitionResult parse(String rawJson, {MealType? defaultMealType}) {
    final cleaned = _extractJson(rawJson);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw LlmSchemaException('无法解析 JSON');
    }

    final mealName = json['meal_name'] as String? ?? '未识别餐食';
    final itemsRaw = json['items'] as List? ?? [];
    final overallConfidence = FoodItem.parseConfidence(json['overall_confidence'] as String?);
    final notes = json['notes'] as String?;

    if (itemsRaw.isEmpty) {
      throw LlmSchemaException('识别到 0 个食材');
    }
    if (itemsRaw.length > 30) {
      throw LlmSchemaException('食材数量过多（${itemsRaw.length}），请确认');
    }

    final List<FoodItem> foodItems = [];
    for (var i = 0; i < itemsRaw.length; i++) {
      final item = itemsRaw[i] as Map<String, dynamic>;
      final name = item['name'] as String? ?? '未知食材';
      final weightG = _parseDouble(item['weight_g']);
      final kcal = _parseDouble(item['kcal']);
      final carbsG = _parseDouble(item['carbs_g']);
      final proteinG = _parseDouble(item['protein_g']);
      final fatG = _parseDouble(item['fat_g']);
      final confidence = FoodItem.parseConfidence(item['confidence'] as String?);

      // 矿物质和维生素：LLM 返回定长数组，解析失败时为 null
      final mineralsRaw = item['minerals'];
      final vitaminsRaw = item['vitamins'];
      final minerals = (mineralsRaw is List)
          ? MicronutrientList.fromLlmList(mineralsRaw, length: Mineral.values.length)
          : null;
      final vitamins = (vitaminsRaw is List)
          ? MicronutrientList.fromLlmList(vitaminsRaw, length: Vitamin.values.length)
          : null;

      if (kcal < 0 || carbsG < 0 || proteinG < 0 || fatG < 0 || weightG < 0) {
        throw LlmSchemaException('食材「$name」存在负数数值');
      }

      foodItems.add(FoodItem(
        name: name,
        weightG: weightG,
        kcal: kcal,
        carbsG: carbsG,
        proteinG: proteinG,
        fatG: fatG,
        confidence: confidence,
        sortOrder: i,
        minerals: minerals,
        vitamins: vitamins,
      ));
    }

    return LlmRecognitionResult(
      mealName: mealName,
      foodItems: foodItems,
      overallConfidence: overallConfidence,
      notes: notes,
      rawResponse: rawJson,
    );
  }

  static String _extractJson(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed.isNaN || parsed.isInfinite) {
        throw LlmSchemaException('数值无效: $value');
      }
      return parsed;
    }
    throw LlmSchemaException('数值类型无效: $value');
  }



  static MealDraft toDraft(LlmRecognitionResult result, {String? photoTempPath, MealType? mealType}) {
    return MealDraft(
      photoTempPath: photoTempPath,
      mealName: result.mealName,
      mealType: mealType ?? MealType.guessFromHour(DateTime.now().hour),
      foodItems: result.foodItems,
      overallConfidence: result.overallConfidence,
      notes: result.notes,
      rawResponse: result.rawResponse,
    );
  }
}
