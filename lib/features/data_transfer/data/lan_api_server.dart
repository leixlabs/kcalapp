import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import '../../diary/domain/daily_goal.dart';
import '../../diary/domain/meal.dart';
import '../../diary/domain/micronutrients.dart';

class LanApiServer {
  LanApiServer({
    required this.loadMeals,
    required this.loadGoals,
    InternetAddress? bindAddress,
    this.port = defaultPort,
    this.advertisedAddresses,
  }) : bindAddress = bindAddress ?? InternetAddress.anyIPv4;

  static const int defaultPort = 8765;

  final Future<List<Meal>> Function() loadMeals;
  final Future<List<DailyGoal>> Function() loadGoals;
  final InternetAddress bindAddress;
  final int port;
  final List<String>? advertisedAddresses;

  HttpServer? _server;
  String? _accessToken;
  List<String> _addresses = const [];

  bool get isRunning => _server != null;
  int? get boundPort => _server?.port;
  String? get accessToken => _accessToken;
  List<String> get addresses => List.unmodifiable(_addresses);

  Future<void> start() async {
    if (_server != null) return;

    final server = await HttpServer.bind(bindAddress, port, shared: false);
    try {
      final addresses =
          advertisedAddresses ?? await _findPrivateIpv4Addresses();
      if (addresses.isEmpty) {
        throw StateError('未检测到可用的局域网 IPv4 地址');
      }

      _server = server;
      _addresses = List.unmodifiable(addresses);
      _accessToken = _generateToken();
      server.listen(
        (request) => _handleRequest(request),
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'LAN API server error',
            name: 'calory.lan_api',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (_) {
      await server.close(force: true);
      rethrow;
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _accessToken = null;
    _addresses = const [];
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method != 'GET') {
      await _writeJson(request, HttpStatus.methodNotAllowed, {
        'error': 'method_not_allowed',
      });
      return;
    }

    final token = _accessToken;
    if (token == null || !_isAuthorized(request, token)) {
      await _writeJson(request, HttpStatus.unauthorized, {
        'error': 'unauthorized',
      });
      return;
    }

    switch (request.uri.path) {
      case '/':
        await _writeDocumentation(request, token);
      case '/api/v1/health':
        await _writeJson(request, HttpStatus.ok, {
          'status': 'ok',
          'api_version': 1,
        });
      case '/api/v1/meals':
        final fromValue = request.uri.queryParameters['from'];
        final toValue = request.uri.queryParameters['to'];
        final from = fromValue == null ? null : DateTime.tryParse(fromValue);
        final to = toValue == null ? null : DateTime.tryParse(toValue);
        if ((fromValue != null && from == null) ||
            (toValue != null && to == null) ||
            (from != null && to != null && from.isAfter(to))) {
          await _writeJson(request, HttpStatus.badRequest, {
            'error': 'invalid_time_range',
          });
          return;
        }
        try {
          final meals = await loadMeals();
          await _writeJson(request, HttpStatus.ok, {
            'data': meals
                .where(
                  (meal) =>
                      (from == null || !meal.dateTime.isBefore(from)) &&
                      (to == null || meal.dateTime.isBefore(to)),
                )
                .map(_mealToJson)
                .toList(),
          });
        } catch (error, stackTrace) {
          _logRequestError(error, stackTrace);
          await _writeJson(request, HttpStatus.internalServerError, {
            'error': 'internal_server_error',
          });
        }
      case '/api/v1/goals':
        try {
          final goals = await loadGoals();
          await _writeJson(request, HttpStatus.ok, {
            'data': goals.map(_goalToJson).toList(),
          });
        } catch (error, stackTrace) {
          _logRequestError(error, stackTrace);
          await _writeJson(request, HttpStatus.internalServerError, {
            'error': 'internal_server_error',
          });
        }
      default:
        await _writeJson(request, HttpStatus.notFound, {'error': 'not_found'});
    }
  }

  bool _isAuthorized(HttpRequest request, String token) {
    final bearerToken = request.headers
        .value(HttpHeaders.authorizationHeader)
        ?.replaceFirst(RegExp(r'^Bearer '), '');
    final queryToken = request.uri.queryParameters['token'];
    return _constantTimeEquals(bearerToken ?? '', token) ||
        _constantTimeEquals(queryToken ?? '', token);
  }

  Future<void> _writeDocumentation(HttpRequest request, String token) async {
    final encodedToken = Uri.encodeQueryComponent(token);
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.html;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.write('''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Calory 局域网只读 API</title>
<style>body{font:16px/1.6 system-ui,sans-serif;max-width:860px;margin:40px auto;padding:0 20px;color:#1f2937}code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;background:#f3f4f6}code{padding:2px 5px;border-radius:4px}pre{padding:14px;border-radius:8px;overflow:auto}h1{margin-bottom:0}h2{margin-top:32px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #d1d5db;padding:8px;text-align:left}a{color:#2563eb}</style>
</head><body>
<h1>Calory 局域网只读 API</h1>
<p>此服务仅提供当前设备的餐食和每日营养目标，所有接口均为只读 JSON；不返回图片、图片路径、LLM 配置或 API Key。</p>
<h2>认证</h2>
<p>可任选一种方式：URL 查询参数 <code>?token=...</code>（适合浏览器和直接粘贴的链接），或 HTTP 请求头 <code>Authorization: Bearer &lt;token&gt;</code>。令牌仅在本页面对应的服务运行期间有效。</p>
<pre>curl 'http://&lt;局域网地址&gt;:&lt;端口&gt;/api/v1/meals?token=$encodedToken&amp;from=2026-09-01T00%3A00%3A00Z&amp;to=2026-10-01T00%3A00%3A00Z'</pre>
<h2>接口</h2>
<table><thead><tr><th>方法</th><th>路径</th><th>用途</th></tr></thead><tbody>
<tr><td>GET</td><td><a href="/api/v1/health?token=$encodedToken">/api/v1/health</a></td><td>检查服务状态，返回 <code>{"status":"ok","api_version":1}</code></td></tr>
<tr><td>GET</td><td><a href="/api/v1/meals?token=$encodedToken">/api/v1/meals</a></td><td>读取餐食、总营养和食材明细；可用 <code>from</code>、<code>to</code> 筛选时间范围</td></tr>
<tr><td>GET</td><td><a href="/api/v1/goals?token=$encodedToken">/api/v1/goals</a></td><td>读取每日营养目标</td></tr>
</tbody></table>
<h2>响应模型</h2>
<p>成功响应均为 <code>{"data":[...]}</code>，健康检查除外。日期时间为 ISO 8601 字符串；<code>effective_date</code> 为 <code>YYYY-MM-DD</code>。</p>
<h2>时间范围筛选</h2>
<p><code>GET /api/v1/meals</code> 支持可选参数 <code>from</code> 和 <code>to</code>，值为 ISO 8601 时间（建议使用 UTC，例如 <code>2026-09-01T00:00:00Z</code>）。<code>from</code> 为包含边界，<code>to</code> 为不包含边界；省略任一参数表示该侧不设限制。时间格式不合法或 <code>from</code> 晚于 <code>to</code> 时，返回 400 <code>{"error":"invalid_time_range"}</code>。</p>
<pre>{
  "data": [{
    "id": 1, "date_time": "2026-09-29T12:00:00.000",
    "meal_type": "lunch", "name": "午餐", "servings": 1,
    "total_nutrition": {"kcal": 650, "carbs_g": 80, "protein_g": 30, "fat_g": 18},
    "food_items": [{"id": 2, "name": "米饭", "weight_g": 200, "kcal": 232,
      "carbs_g": 52, "protein_g": 5, "fat_g": 1, "minerals": {}, "vitamins": {}}]
  }]
}</pre>
<p>餐食还可能包含 <code>nutrition_review</code>、<code>source</code>、<code>ai_recognition_status</code>、<code>created_at</code> 和 <code>updated_at</code>。目标对象包含 <code>id</code>、<code>effective_date</code>、<code>kcal</code>、<code>carbs_g</code>、<code>protein_g</code>、<code>fat_g</code>。</p>
<h2>错误</h2><p>认证失败返回 401 <code>{"error":"unauthorized"}</code>；未知路径返回 404；非 GET 请求返回 405。</p>
</body></html>''');
    await response.close();
  }

  void _logRequestError(Object error, StackTrace stackTrace) {
    developer.log(
      'LAN API request failed',
      name: 'calory.lan_api',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _writeJson(
    HttpRequest request,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    final response = request.response;
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.write(jsonEncode(body));
    await response.close();
  }

  Map<String, Object?> _mealToJson(Meal meal) => {
    'id': meal.id,
    'date_time': meal.dateTime.toIso8601String(),
    'meal_type': meal.mealType.name,
    'name': meal.name,
    'nutrition_review': meal.nutritionReview,
    'servings': meal.servings,
    'source': meal.source,
    'ai_recognition_status': meal.aiRecognitionStatus.name,
    'created_at': meal.createdAt.toIso8601String(),
    'updated_at': meal.updatedAt.toIso8601String(),
    'total_nutrition': {
      'kcal': meal.totalNutrition.kcal,
      'carbs_g': meal.totalNutrition.carbsG,
      'protein_g': meal.totalNutrition.proteinG,
      'fat_g': meal.totalNutrition.fatG,
    },
    'food_items': meal.foodItems
        .map(
          (item) => {
            'id': item.id,
            'name': item.name,
            'category_id': item.categoryId,
            'weight_g': item.weightG,
            'kcal': item.kcal,
            'carbs_g': item.carbsG,
            'protein_g': item.proteinG,
            'fat_g': item.fatG,
            'confidence': item.confidence?.name,
            'sort_order': item.sortOrder,
            'minerals': _micronutrientsToJson(
              item.minerals,
              Mineral.values,
              (mineral) => mineral.name,
            ),
            'vitamins': _micronutrientsToJson(
              item.vitamins,
              Vitamin.values,
              (vitamin) => vitamin.name,
            ),
          },
        )
        .toList(),
  };

  Map<String, double?>? _micronutrientsToJson<T>(
    List<double?>? values,
    List<T> nutrients,
    String Function(T nutrient) getName,
  ) {
    if (values == null) return null;
    return {
      for (var i = 0; i < nutrients.length; i++)
        getName(nutrients[i]): values[i],
    };
  }

  Map<String, Object?> _goalToJson(DailyGoal goal) => {
    'id': goal.id,
    'effective_date': _dateOnly(goal.effectiveDate),
    'kcal': goal.kcal,
    'carbs_g': goal.carbsG,
    'protein_g': goal.proteinG,
    'fat_g': goal.fatG,
  };

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<List<String>> _findPrivateIpv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    final addresses = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (_isPrivateIpv4(address.address)) addresses.add(address.address);
      }
    }
    return addresses.toList()..sort();
  }

  bool _isPrivateIpv4(String address) {
    final octets = address.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((octet) => octet == null)) {
      return false;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  String _generateToken() {
    final random = Random.secure();
    return List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  bool _constantTimeEquals(String actual, String expected) {
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return difference == 0;
  }
}
