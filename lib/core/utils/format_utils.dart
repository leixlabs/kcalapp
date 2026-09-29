import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String formatKcal(double kcal) {
    return '${kcal.round()} kcal';
  }

  static String formatGrams(double g) {
    if (g == g.roundToDouble()) return '${g.round()} g';
    return '${g.toStringAsFixed(1)} g';
  }

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

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static String dayLabel(DateTime date) {
    if (isToday(date)) return '今天';
    if (isSameDay(date, DateTime.now().add(const Duration(days: 1)))) return '明天';
    if (isSameDay(date, DateTime.now().subtract(const Duration(days: 1)))) return '昨天';
    return formatDate(date);
  }

  static String relativeFromNow(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays > 0) return '${diff.inDays}天后';
    return '${-diff.inDays}天前';
  }
}
