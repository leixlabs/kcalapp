import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  /// 数值部分：整数不带小数，否则保留 1 位，如 `12` / `12.5`。
  static String formatGramValue(double g) {
    return g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
  }

  static String formatGrams(double g) => '${formatGramValue(g)} g';

  static String formatDate(DateTime date) {
    return DateFormat('M月d日 EEEE', 'zh_CN').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('M月d日', 'zh_CN').format(date);
  }

  /// 用于顶部日期选择器，如「2026年09月29日 ▾」
  static String formatDateChinese(DateTime date) {
    return DateFormat('yyyy年MM月dd日', 'zh_CN').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm', 'zh_CN').format(time);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
}
