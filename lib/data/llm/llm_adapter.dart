import 'dart:convert';
import 'dart:io';
import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import '../../features/llm_settings/domain/llm_profile.dart';
import 'llm_schema.dart';

class LlmAdapter {
  final Dio _dio;

  LlmAdapter({Alice? alice}) : _dio = Dio() {
    if (alice != null) {
      final adapter = AliceDioAdapter();
      alice.addAdapter(adapter);
      _dio.interceptors.add(adapter);
    }
  }

  Future<LlmRecognitionResult> recognizeFood({
    required LlmProfile profile,
    required String apiKey,
    required String imagePath,
    String language = 'zh',
    MealTypeHint? mealTypeHint,
    CancelToken? cancelToken,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final prompt = _buildPrompt(language, mealTypeHint);

    final response = await _dio.post(
      '${profile.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        sendTimeout: Duration(seconds: profile.timeoutSeconds),
        receiveTimeout: Duration(seconds: profile.timeoutSeconds),
      ),
      data: {
        'model': profile.model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              },
            ],
          },
        ],
        'max_tokens': 2000,
        // 若服务支持结构化输出，通过 JSON Schema 约束模型输出，
        // 比 json_object 模式更严格：字段名、类型、枚举值均由 schema 保证，
        // 不再依赖 prompt 描述格式。不支持该参数的服务请在设置中关闭 JSON Mode。
        if (profile.useJsonMode) 'response_format': _buildResponseFormat(),
      },
      cancelToken: cancelToken,
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    return LlmSchemaValidator.parse(content);
  }

  Future<bool> testConnection({
    required LlmProfile profile,
    required String apiKey,
  }) async {
    try {
      final response = await _dio.post(
        '${profile.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': profile.model,
          'messages': [
            {'role': 'user', 'content': '请回复"OK"'}
          ],
          'max_tokens': 10,
        },
      );
      final content = response.data['choices'][0]['message']['content'] as String;
      return content.isNotEmpty;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String _buildPrompt(String language, MealTypeHint? hint) {
    final mealHint = hint != null ? '\n餐次提示: ${hint.label}' : '';
    return '''请分析这张餐食图片，识别其中的食物。$mealHint

要求：
- 只识别图片中可见的食物，不要编造图片中不存在的内容
- weight_g、kcal、carbs_g、protein_g、fat_g 均为估算值，必须为非负数
- confidence 表示你对该食材识别和营养估算的置信度''';
  }

  /// 构造 OpenAI Structured Outputs 所需的 response_format 对象。
  /// 使用 json_schema 类型而非 json_object，让模型严格按 schema 输出，
  /// 字段名、类型与枚举值均由 schema 约束，无需在 prompt 中重复描述格式。
  static Map<String, dynamic> _buildResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'food_recognition',
        'strict': true,
        'schema': {
          'type': 'object',
          'properties': {
            'meal_name': {'type': 'string', 'description': '餐食名称'},
            'items': {
              'type': 'array',
              'description': '图片中识别到的食材列表',
              'items': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string', 'description': '食材名称'},
                  'weight_g': {'type': 'number', 'description': '估算重量（克）'},
                  'kcal': {'type': 'number', 'description': '估算热量（千卡）'},
                  'carbs_g': {'type': 'number', 'description': '碳水化合物（克）'},
                  'protein_g': {'type': 'number', 'description': '蛋白质（克）'},
                  'fat_g': {'type': 'number', 'description': '脂肪（克）'},
                  'confidence': {
                    'type': 'string',
                    'enum': ['low', 'medium', 'high'],
                    'description': '对该食材识别和营养估算的置信度',
                  },
                  // 矿物质：11 个数字，按位对应 铁/锌/铜/硒/碘/钼/铬/钴/钙/钠/镁
                  // 不确定时填 0，不可省略元素。
                  'minerals': {
                    'type': 'array',
                    'description': '微量矿物质（mg/μg），11 个元素，顺序：铁(mg) 锌(mg) 铜(mg) 硒(μg) 碘(μg) 钼(μg) 铬(μg) 钴(μg) 钙(mg) 钠(mg) 镁(mg)，不确定时填 0',
                    'items': {'type': 'number'},
                    'minItems': 11,
                    'maxItems': 11,
                  },
                  // 维生素：13 个数字，按位对应 A/B1/B2/B3/B5/B6/B7/B9/B12/C/D/E/K
                  // 不确定时填 0，不可省略元素。
                  'vitamins': {
                    'type': 'array',
                    'description': '维生素（mg/μg），13 个元素，顺序：VA(μg) VB1(mg) VB2(mg) VB3(mg) VB5(mg) VB6(mg) VB7(μg) VB9(μg) VB12(μg) VC(mg) VD(μg) VE(mg) VK(μg)，不确定时填 0',
                    'items': {'type': 'number'},
                    'minItems': 13,
                    'maxItems': 13,
                  },
                },
                'required': ['name', 'weight_g', 'kcal', 'carbs_g', 'protein_g', 'fat_g', 'confidence', 'minerals', 'vitamins'],
                'additionalProperties': false,
              },
            },
            'overall_confidence': {
              'type': 'string',
              'enum': ['low', 'medium', 'high'],
              'description': '对整餐识别结果的整体置信度',
            },
            'notes': {
              'type': 'string',
              'description': '补充说明，如份量估算依据',
            },
          },
          'required': ['meal_name', 'items', 'overall_confidence', 'notes'],
          'additionalProperties': false,
        },
      },
    };
  }

  LlmConnectionError _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return LlmConnectionError.timeout;
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return LlmConnectionError.unauthorized;
    }
    if (statusCode == 429) {
      return LlmConnectionError.rateLimited;
    }
    if (statusCode != null && statusCode >= 500) {
      return LlmConnectionError.serverError;
    }
    return LlmConnectionError.unknown;
  }
}

enum MealTypeHint { breakfast, lunch, dinner, snack }

extension on MealTypeHint {
  String get label => switch (this) {
        MealTypeHint.breakfast => '早餐',
        MealTypeHint.lunch => '午餐',
        MealTypeHint.dinner => '晚餐',
        MealTypeHint.snack => '加餐',
      };
}

enum LlmConnectionError { timeout, unauthorized, rateLimited, serverError, unknown, parseError }
