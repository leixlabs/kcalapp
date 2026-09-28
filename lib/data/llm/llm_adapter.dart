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
    return '''请分析这张餐食图片，识别其中的食物。
$mealHint
请返回 JSON 格式（不要包含 markdown 标记），结构如下：
{
  "meal_name": "餐名",
  "items": [
    {
      "name": "食材名",
      "weight_g": 估算重量克数,
      "kcal": 估算热量,
      "carbs_g": 碳水克数,
      "protein_g": 蛋白质克数,
      "fat_g": 脂肪克数,
      "confidence": "low|medium|high"
    }
  ],
  "overall_confidence": "low|medium|high",
  "notes": "补充说明，如份量估算依据"
}

要求：
- 只识别图片中可见的食物
- 不要编造图片中不存在的内容
- 重量、热量和营养素为估算值
- confidence 表示你对识别和估算的置信度''';
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
