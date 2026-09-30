import 'dart:convert';
import 'dart:io';

import 'package:calory/features/data_transfer/data/lan_api_server.dart';
import 'package:calory/features/diary/domain/daily_goal.dart';
import 'package:calory/features/diary/domain/food_item.dart';
import 'package:calory/features/diary/domain/meal.dart';
import 'package:calory/features/diary/domain/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LanApiServer server;
  late HttpClient client;

  setUp(() {
    final date = DateTime(2026, 9, 29, 12);
    server = LanApiServer(
      bindAddress: InternetAddress.loopbackIPv4,
      port: 0,
      advertisedAddresses: const ['127.0.0.1'],
      loadMeals: () async => [
        Meal(
          id: 1,
          dateTime: date,
          mealType: MealType.lunch,
          name: '午餐',
          photoPath: '/private/photos/lunch.jpg',
          servings: 2,
          foodItems: const [
            FoodItem(
              id: 2,
              name: '米饭',
              weightG: 100,
              kcal: 130,
              carbsG: 28,
              proteinG: 2.7,
              fatG: 0.3,
            ),
          ],
          createdAt: date,
          updatedAt: date,
        ),
      ],
      loadGoals: () async => [
        DailyGoal(
          id: 3,
          effectiveDate: DateTime(2026, 9, 1),
          kcal: 1800,
          carbsG: 240,
          proteinG: 90,
          fatG: 60,
        ),
      ],
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
  });

  test('requires the temporary bearer token', () async {
    await server.start();

    final unauthorized = await _get(client, server, '/api/v1/health');
    expect(unauthorized.statusCode, HttpStatus.unauthorized);
    expect(jsonDecode(unauthorized.body), {'error': 'unauthorized'});

    final authorized = await _get(
      client,
      server,
      '/api/v1/health',
      token: server.accessToken,
    );
    expect(authorized.statusCode, HttpStatus.ok);
    expect(jsonDecode(authorized.body), {'status': 'ok', 'api_version': 1});
    expect(server.accessToken, hasLength(64));
  });

  test(
    'accepts the token in the URL and renders API documentation at root',
    () async {
      await server.start();

      final documentation = await _get(
        client,
        server,
        '/?token=${server.accessToken}',
      );
      expect(documentation.statusCode, HttpStatus.ok);
      expect(documentation.contentType, startsWith('text/html'));
      expect(documentation.body, contains('Calory 局域网只读 API'));
      expect(documentation.body, contains('/api/v1/meals?token='));

      final mealsResponse = await _get(
        client,
        server,
        '/api/v1/meals?token=${server.accessToken}',
      );
      expect(mealsResponse.statusCode, HttpStatus.ok);
    },
  );

  test('exposes meals and goals without photo paths', () async {
    await server.start();

    final mealsResponse = await _get(
      client,
      server,
      '/api/v1/meals',
      token: server.accessToken,
    );
    final meals = (jsonDecode(mealsResponse.body) as Map)['data'] as List;
    final meal = meals.single as Map;
    expect(meal['name'], '午餐');
    expect((meal['total_nutrition'] as Map)['kcal'], 260);
    expect(meal.containsKey('photo_path'), isFalse);
    expect(meal['food_items'], hasLength(1));

    final goalsResponse = await _get(
      client,
      server,
      '/api/v1/goals',
      token: server.accessToken,
    );
    final goals = (jsonDecode(goalsResponse.body) as Map)['data'] as List;
    expect((goals.single as Map)['effective_date'], '2026-09-01');
    expect((goals.single as Map)['protein_g'], 90);
  });

  test('filters meals by an inclusive start and exclusive end time', () async {
    await server.start();

    final included = await _get(
      client,
      server,
      '/api/v1/meals?token=${server.accessToken}&from=2026-09-29T12:00:00&to=2026-09-29T12:01:00',
    );
    expect(included.statusCode, HttpStatus.ok);
    expect((jsonDecode(included.body) as Map)['data'], hasLength(1));

    final excluded = await _get(
      client,
      server,
      '/api/v1/meals?token=${server.accessToken}&to=2026-09-29T12:00:00',
    );
    expect(excluded.statusCode, HttpStatus.ok);
    expect((jsonDecode(excluded.body) as Map)['data'], isEmpty);

    final invalid = await _get(
      client,
      server,
      '/api/v1/meals?token=${server.accessToken}&from=not-a-time',
    );
    expect(invalid.statusCode, HttpStatus.badRequest);
    expect(jsonDecode(invalid.body), {'error': 'invalid_time_range'});
  });
}

Future<_Response> _get(
  HttpClient client,
  LanApiServer server,
  String path, {
  String? token,
}) async {
  final request = await client.getUrl(
    Uri.parse('http://127.0.0.1:${server.boundPort}$path'),
  );
  if (token != null) {
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bear'
      'er $token',
    );
  }
  final response = await request.close();
  return _Response(
    response.statusCode,
    await response.transform(utf8.decoder).join(),
    response.headers.contentType?.mimeType,
  );
}

class _Response {
  const _Response(this.statusCode, this.body, this.contentType);

  final int statusCode;
  final String body;
  final String? contentType;
}
