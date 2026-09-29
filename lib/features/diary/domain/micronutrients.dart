import 'dart:convert';

// ─────────────────────────────────────────────
// Mineral（矿物质）8 个，按位固定顺序 index 0-7
// ─────────────────────────────────────────────

/// 微量矿物质枚举。index 即 [FoodItem.minerals] 数组中的位置。
enum Mineral {
  iron, // 0 铁  Fe  mg
  zinc, // 1 锌  Zn  mg
  copper, // 2 铜  Cu  mg
  selenium, // 3 硒  Se  μg
  iodine, // 4 碘  I   μg
  molybdenum, // 5 钼  Mo  μg
  chromium, // 6 铬  Cr  μg
  cobalt, // 7 钴  Co  μg
  calcium, // 8 钙  Ca  mg
  sodium, // 9 钠  Na  mg
  magnesium; // 10 镁 Mg  mg

  String get label =>
      const ['铁', '锌', '铜', '硒', '碘', '钼', '铬', '钴', '钙', '钠', '镁'][index];
  String get symbol => const [
    'Fe',
    'Zn',
    'Cu',
    'Se',
    'I',
    'Mo',
    'Cr',
    'Co',
    'Ca',
    'Na',
    'Mg',
  ][index];

  /// 硒至钴单位为 μg；其余矿物质单位为 mg。
  bool get isUg => index >= 3 && index <= 7;
  String get unit => isUg ? 'μg' : 'mg';
}

// ─────────────────────────────────────────────
// Vitamin（维生素）13 个，按位固定顺序 index 0-12
// ─────────────────────────────────────────────

/// 维生素枚举。index 即 [FoodItem.vitamins] 数组中的位置。
enum Vitamin {
  a, //  0 维生素 A   μg RAE
  b1, //  1 维生素 B1  mg  硫胺素
  b2, //  2 维生素 B2  mg  核黄素
  b3, //  3 维生素 B3  mg  烟酸
  b5, //  4 维生素 B5  mg  泛酸
  b6, //  5 维生素 B6  mg
  b7, //  6 维生素 B7  μg  生物素
  b9, //  7 维生素 B9  μg  叶酸
  b12, //  8 维生素 B12 μg
  c, //  9 维生素 C   mg
  d, // 10 维生素 D   μg
  e, // 11 维生素 E   mg
  k; // 12 维生素 K   μg

  String get label => const [
    'VA',
    'VB1',
    'VB2',
    'VB3',
    'VB5',
    'VB6',
    'VB7',
    'VB9',
    'VB12',
    'VC',
    'VD',
    'VE',
    'VK',
  ][index];

  String get fullLabel => const [
    '维生素A',
    '维生素B1',
    '维生素B2',
    '维生素B3(烟酸)',
    '维生素B5',
    '维生素B6',
    '维生素B7(生物素)',
    '维生素B9(叶酸)',
    '维生素B12',
    '维生素C',
    '维生素D',
    '维生素E',
    '维生素K',
  ][index];

  /// μg 级维生素：A/B7/B9/B12/D/K
  bool get isUg => const {0, 6, 7, 8, 10, 12}.contains(index);
  String get unit => isUg ? 'μg' : 'mg';
}

// ─────────────────────────────────────────────
// MicronutrientList — 通用工具（矿物质/维生素共用）
// ─────────────────────────────────────────────

/// 通用工具类，供 [Mineral] 和 [Vitamin] 数组使用。
///
/// 规范：
///   - 列表长度固定（矿物质 8，维生素 13）
///   - 元素 `null`：该项数据未知
///   - 整个列表 `null`：无此类微量营养素数据（手动录入的历史记录）
class MicronutrientList {
  MicronutrientList._();

  /// 从 JSON 字符串解析为固定长度列表。长度不匹配或解析失败时返回 null。
  static List<double?>? fromJson(String? jsonStr, {required int length}) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final list = jsonDecode(jsonStr) as List;
      if (list.length == length) return list.map(_toNullableDouble).toList();
      // Older database rows contain the original eight mineral values.
      if (length == Mineral.values.length && list.length == 8) {
        return [
          ...list.map(_toNullableDouble),
          ...List<double?>.filled(length - list.length, null),
        ];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 序列化为 JSON 字符串。list 为 null 时返回 null。
  static String? toJson(List<double?>? list) {
    if (list == null) return null;
    return jsonEncode(list);
  }

  /// 从 LLM 返回的原始数组构造固定长度列表。长度不足补 null，超出截断。
  static List<double?> fromLlmList(List<dynamic> raw, {required int length}) {
    return List.generate(length, (i) {
      if (i >= raw.length) return null;
      return _toNullableDouble(raw[i]);
    });
  }

  /// 按 servings 缩放（null 保持 null）。
  static List<double?>? scale(List<double?>? list, double servings) {
    if (list == null) return null;
    return list.map((v) => v == null ? null : v * servings).toList();
  }

  /// 将两个等长列表对应位相加。任一元素为 null 则结果该位为 null。
  static List<double?>? add(
    List<double?>? a,
    List<double?>? b, {
    required int length,
  }) {
    if (a == null && b == null) return null;
    final la = a ?? List.filled(length, null);
    final lb = b ?? List.filled(length, null);
    return List.generate(length, (i) {
      final va = la[i];
      final vb = lb[i];
      return (va == null || vb == null) ? null : va + vb;
    });
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final d = v.toDouble();
      return (d.isNaN || d.isInfinite || d < 0) ? null : d;
    }
    return null;
  }
}
