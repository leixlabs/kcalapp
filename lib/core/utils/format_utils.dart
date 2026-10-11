import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String _locale() => Intl.defaultLocale ?? 'zh';

  static bool _isZh() => _locale().toLowerCase().startsWith('zh');

  /// 数值部分：整数不带小数，否则保留 1 位，如 `12` / `12.5`。
  static String formatGramValue(double g) {
    return g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
  }

  static String formatGrams(double g) => '${formatGramValue(g)} g';

  static String formatDate(DateTime date) {
    final locale = _locale();
    return DateFormat(_isZh() ? 'M月d日 EEEE' : 'EEEE, MMM d', locale).format(date);
  }

  static String formatDateShort(DateTime date) {
    final locale = _locale();
    return DateFormat(_isZh() ? 'M月d日' : 'MMM d', locale).format(date);
  }

  /// 用于顶部日期选择器，如「2026年09月29日 ▾」。
  static String formatDateChinese(DateTime date) {
    final locale = _locale();
    return DateFormat(
      _isZh() ? 'yyyy年MM月dd日' : 'MMM d, yyyy',
      locale,
    ).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm', _locale()).format(time);
  }

  /// 分享卡片上的周区间，如「2026年9月28日 – 10月4日」。
  static String formatWeekRange(DateTime start, DateTime end) {
    final locale = _locale();
    if (_isZh()) {
      final startText = DateFormat('yyyy年M月d日', locale).format(start);
      final endText = start.year == end.year
          ? DateFormat('M月d日', locale).format(end)
          : DateFormat('yyyy年M月d日', locale).format(end);
      return '$startText – $endText';
    }
    final startText = DateFormat('MMM d, yyyy', locale).format(start);
    final endText = start.year == end.year
        ? DateFormat('MMM d', locale).format(end)
        : DateFormat('MMM d, yyyy', locale).format(end);
    return '$startText – $endText';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
}
