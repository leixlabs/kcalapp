import 'dart:io';

import 'package:calory/data/llm/llm_adapter.dart';
import 'package:calory/features/llm_settings/domain/llm_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

LlmProfile _profile({
  LlmResponseFormat responseFormat = LlmResponseFormat.jsonSchema,
}) => LlmProfile(
  displayName: 'test',
  baseUrl: 'https://example.test/v1',
  model: 'test-model',
  createdAt: DateTime(2026),
  responseFormat: responseFormat,
);

Dio _respondWith(
  String content, {
  String? finishReason,
  void Function(RequestOptions)? onRequest,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest?.call(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'choices': [
                {
                  'message': {'content': content},
                  'finish_reason': finishReason,
                },
              ],
            },
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  test('checks the JSON Schema format and uses the configured API key', () async {
    RequestOptions? request;
    final dio = _respondWith(
      '{"meal_name":"连通性测试","items":[],"overall_confidence":"high","notes":"验证成功"}',
      onRequest: (options) => request = options,
    );
    final adapter = LlmAdapter(dio: dio);

    expect(
      await adapter.testConnection(profile: _profile(), apiKey: 'test-key'),
      isTrue,
    );
    expect(request!.data['response_format']['type'], 'json_schema');
    expect(
      request!
          .data['response_format']['json_schema']['schema']['properties']['items']['items']['properties']['category_id']['enum'],
      [
        'grains',
        'vegetables_fruits',
        'meat_eggs_seafood',
        'dairy_beans_nuts',
        'other',
      ],
    );
    expect(request!.headers['Authorization'], 'Bearer test-key');

    dio.close(force: true);
  });

  test('uses JSON Mode response_format when selected', () async {
    RequestOptions? request;
    final dio = _respondWith(
      '{"ok":true}',
      onRequest: (options) => request = options,
    );
    final adapter = LlmAdapter(dio: dio);

    expect(
      await adapter.testConnection(
        profile: _profile(responseFormat: LlmResponseFormat.jsonMode),
        apiKey: 'test-key',
      ),
      isTrue,
    );
    expect(request!.data['response_format'], {'type': 'json_object'});
    expect(request!.headers['Authorization'], 'Bearer test-key');

    dio.close(force: true);
  });

  test('detects responses truncated by the output token limit', () async {
    final tempDir = await Directory.systemTemp.createTemp('llm-truncated-');
    try {
      final image = File('${tempDir.path}/meal.jpg');
      await image.writeAsBytes([0]);
      RequestOptions? request;
      final dio = _respondWith(
        '{"meal_name":"晚餐","items":[',
        finishReason: 'length',
        onRequest: (options) => request = options,
      );
      final adapter = LlmAdapter(dio: dio);

      await expectLater(
        adapter.recognizeFood(
          profile: _profile(),
          apiKey: 'test-key',
          imagePath: image.path,
        ),
        throwsA(isA<LlmResponseTruncatedException>()),
      );
      expect(request!.data.containsKey('max_tokens'), isFalse);
      expect(request!.headers['Authorization'], 'Bearer test-key');
      dio.close(force: true);
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('does not request structured output when disabled', () async {
    RequestOptions? request;
    final dio = _respondWith('OK', onRequest: (options) => request = options);
    final adapter = LlmAdapter(dio: dio);

    expect(
      await adapter.testConnection(
        profile: _profile(responseFormat: LlmResponseFormat.none),
        apiKey: 'test-key',
      ),
      isTrue,
    );
    expect(request!.data.containsKey('response_format'), isFalse);

    dio.close(force: true);
  });

  test('reports when a service rejects the selected response format', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {
                    'error': {'message': 'response_format is not supported'},
                  },
                ),
              ),
            );
          },
        ),
      );
    final adapter = LlmAdapter(dio: dio);

    await expectLater(
      adapter.testConnection(profile: _profile(), apiKey: 'test-key'),
      throwsA(
        isA<LlmConnectionFailure>()
            .having(
              (failure) => failure.error,
              'error',
              LlmConnectionError.responseFormatUnsupported,
            )
            .having(
              (failure) => failure.detail,
              'detail',
              'response_format is not supported',
            ),
      ),
    );

    dio.close(force: true);
  });

  test('reports a friendly reason when response content is null', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'choices': [
                    {
                      'message': {'content': null},
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
    final adapter = LlmAdapter(dio: dio);

    await expectLater(
      adapter.testConnection(profile: _profile(), apiKey: 'test-key'),
      throwsA(
        isA<LlmConnectionFailure>()
            .having(
              (failure) => failure.error,
              'error',
              LlmConnectionError.invalidResponse,
            )
            .having((failure) => failure.detail, 'detail', contains('未返回文本内容')),
      ),
    );

    dio.close(force: true);
  });

  test('preserves a readable service error message', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'error': {'message': 'Invalid API key'},
                  },
                ),
              ),
            );
          },
        ),
      );
    final adapter = LlmAdapter(dio: dio);

    await expectLater(
      adapter.testConnection(profile: _profile(), apiKey: 'test-key'),
      throwsA(
        isA<LlmConnectionFailure>()
            .having(
              (failure) => failure.error,
              'error',
              LlmConnectionError.unauthorized,
            )
            .having((failure) => failure.detail, 'detail', 'Invalid API key'),
      ),
    );

    dio.close(force: true);
  });
}
