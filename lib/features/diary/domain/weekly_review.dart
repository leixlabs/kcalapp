/// 已持久化的周回顾：一周一条，按周起始日（周一）存储。
///
/// [signature] 是该周饮食记录的指纹，用于判断已存内容是否过期。
class WeeklyReview {
  final DateTime weekStart;
  final String? happened;
  final String? improvement;
  final String signature;
  final DateTime updatedAt;

  const WeeklyReview({
    required this.weekStart,
    this.happened,
    this.improvement,
    this.signature = '',
    required this.updatedAt,
  });
}
