import 'dart:convert';
import 'dart:io';

import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';

import '../../features/llm_settings/domain/llm_profile.dart';
import 'llm_schema.dart';

class LlmAdapter {
  final Dio _dio;

  LlmAdapter({Alice? alice, Dio? dio}) : _dio = dio ?? Dio() {
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

    final prompt = _buildPrompt(language, mealTypeHint, profile.responseFormat);

    final response = await _dio.post(
      '${profile.baseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          // The following authorization entry overrides the legacy placeholder.
          // ignore: equal_keys_in_map
          'Authorization': 'Bearer $apiKey',
          ...{'Authorization': 'Bearer $apiKey'},
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
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        if (profile.responseFormat != LlmResponseFormat.none)
          'response_format': _buildResponseFormat(profile.responseFormat),
      },
      cancelToken: cancelToken,
    );

    final choice = response.data['choices'][0];
    final finishReason = choice['finish_reason']?.toString().toLowerCase();
    if (finishReason == 'length' || finishReason == 'max_tokens') {
      throw const LlmResponseTruncatedException();
    }
    final content = choice['message']['content'] as String;
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
            // The following authorization entry overrides the legacy placeholder.
            // ignore: equal_keys_in_map
            'Authorization': 'Bearer $apiKey',
            ...{'Authorization': 'Bearer $apiKey'},
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': profile.model,
          'messages': [
            {
              'role': 'user',
              'content': profile.responseFormat == LlmResponseFormat.jsonSchema
                  ? '请返回最简短的有效识别结果：餐名为“连通性测试”，items 为空，overall_confidence 为 high，notes 为“验证成功”。'
                  : profile.responseFormat == LlmResponseFormat.jsonMode
                  ? '请仅返回一个 JSON 对象，包含字段 "ok": true。'
                  : '请回复"OK"',
            },
          ],
          'max_tokens': profile.responseFormat == LlmResponseFormat.jsonSchema
              ? 256
              : 64,
          if (profile.responseFormat != LlmResponseFormat.none)
            'response_format': _buildResponseFormat(profile.responseFormat),
        },
      );
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw const LlmConnectionFailure(
          LlmConnectionError.invalidResponse,
          '服务未返回有效的验证结果',
        );
      }
      final choices = responseData['choices'];
      if (choices is! List || choices.isEmpty || choices.first is! Map) {
        throw const LlmConnectionFailure(
          LlmConnectionError.invalidResponse,
          '服务没有返回可用的回复，请检查接口地址和模型',
        );
      }
      final message = (choices.first as Map)['message'];
      if (message is! Map) {
        throw const LlmConnectionFailure(
          LlmConnectionError.invalidResponse,
          '服务没有返回可用的回复，请检查接口地址和模型',
        );
      }
      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const LlmConnectionFailure(
          LlmConnectionError.invalidResponse,
          '服务未返回文本内容，请确认所选模型支持对话接口',
        );
      }
      if (profile.responseFormat != LlmResponseFormat.none) {
        final dynamic decoded;
        try {
          decoded = jsonDecode(content);
        } on FormatException {
          throw const LlmConnectionFailure(
            LlmConnectionError.invalidResponse,
            '已启用结构化输出，但服务没有返回有效 JSON',
          );
        }
        final isValid =
            decoded is Map<String, dynamic> &&
            (profile.responseFormat == LlmResponseFormat.jsonMode ||
                (decoded['meal_name'] is String &&
                    decoded['items'] is List &&
                    decoded['overall_confidence'] is String &&
                    decoded['notes'] is String));
        if (!isValid) {
          throw const LlmConnectionFailure(
            LlmConnectionError.invalidResponse,
            '服务返回的 JSON 内容不符合所选格式要求',
          );
        }
      }
      return true;
    } on DioException catch (e) {
      if (profile.responseFormat != LlmResponseFormat.none &&
          (e.response?.statusCode == 400 || e.response?.statusCode == 422)) {
        throw LlmConnectionFailure(
          LlmConnectionError.responseFormatUnsupported,
          _responseErrorDetail(e.response?.data) ??
              '服务拒绝了所选 response_format 请求',
        );
      }
      throw LlmConnectionFailure(
        _mapDioError(e),
        _responseErrorDetail(e.response?.data) ??
            (e.response?.statusCode == null
                ? null
                : '服务返回状态码 ${e.response!.statusCode}'),
      );
    }
  }

  String _buildPrompt(
    String language,
    MealTypeHint? hint,
    LlmResponseFormat responseFormat,
  ) {
    final mealHint = hint != null ? '\n餐次提示: ${hint.label}' : '';
    final outputFormat = responseFormat == LlmResponseFormat.jsonSchema
        ? ''
        : '''
- 只输出一个 JSON 对象，不要 Markdown 或额外说明，结构为：{"meal_name":"餐名","items":[{"name":"食材名","category_id":"类别ID","weight_g":0,"kcal":0,"carbs_g":0,"protein_g":0,"fat_g":0,"confidence":"low|medium|high","minerals":[11个数字],"vitamins":[13个数字]}],"overall_confidence":"low|medium|high","notes":"营养建议"}
- 每个食材的 minerals 必须按顺序包含 11 个数值（铁、锌、铜、硒、碘、钼、铬、钴、钙、钠、镁），vitamins 必须按顺序包含 13 个数值（A、B1、B2、B3、B5、B6、B7、B9、B12、C、D、E、K）；未知值填 0''';
    return '''请分析这张餐食图片，识别其中的食物。$mealHint

要求：
- 只识别图片中可见的食物，不要编造图片中不存在的内容
- 为每种食材指定一个食物类别 category_id，按食材本身而不是整道菜判断：grains（谷薯类）、vegetables_fruits（蔬菜水果）、meat_eggs_seafood（动物性食物：畜禽肉、鸡蛋、水产）、dairy_beans_nuts（奶及奶制品、大豆及豆制品、坚果）；无法归入以上类别时填 other。红豆、绿豆等杂豆归入 grains。复合菜品应拆分识别可见的主要食材后分别分类
- weight_g、kcal、carbs_g、protein_g、fat_g 均为估算值，必须为非负数
- confidence 表示你对该食材识别和营养估算的置信度
$outputFormat''';
  }

  /// 构造 OpenAI Structured Outputs 所需的 response_format 对象。
  /// 使用 json_schema 类型而非 json_object，让模型严格按 schema 输出，
  /// 字段名、类型与枚举值均由 schema 约束，无需在 prompt 中重复描述格式。
  static Map<String, dynamic> _buildResponseFormat(
    LlmResponseFormat responseFormat,
  ) {
    if (responseFormat == LlmResponseFormat.jsonMode) {
      return {'type': 'json_object'};
    }
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
                  'category_id': {
                    'type': 'string',
                    'enum': [
                      'grains',
                      'vegetables_fruits',
                      'meat_eggs_seafood',
                      'dairy_beans_nuts',
                      'other',
                    ],
                    'description': '食材类别：谷薯类、蔬菜水果、动物性食物、奶+豆+坚果或其他',
                  },
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
                'required': [
                  'name',
                  'category_id',
                  'weight_g',
                  'kcal',
                  'carbs_g',
                  'protein_g',
                  'fat_g',
                  'confidence',
                  'minerals',
                  'vitamins',
                ],
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
              'description': '营养师评价：对这餐的营养搭配和适量食用给出简短、实用的建议',
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

  String? _responseErrorDetail(dynamic data) {
    dynamic message;
    if (data is Map) {
      final error = data['error'];
      if (error is Map) {
        message = error['message'] ?? error['detail'];
      } else if (error is String) {
        message = error;
      }
      message ??= data['message'] ?? data['detail'];
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    }

    if (message is! String) return null;
    final detail = message
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (detail.isEmpty) return null;
    return detail.length > 160 ? '${detail.substring(0, 160)}…' : detail;
  }
}

class LlmConnectionFailure implements Exception {
  final LlmConnectionError error;
  final String? detail;

  const LlmConnectionFailure(this.error, [this.detail]);
}

class LlmResponseTruncatedException implements Exception {
  const LlmResponseTruncatedException();

  @override
  String toString() => '模型输出达到长度上限，识别结果不完整，请重试或缩短输出内容';
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

enum LlmConnectionError {
  timeout,
  unauthorized,
  rateLimited,
  serverError,
  unknown,
  parseError,
  invalidResponse,
  responseFormatUnsupported,
}
