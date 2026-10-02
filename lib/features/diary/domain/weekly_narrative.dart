/// 周回顾的两段叙述文案：本周实际发生了什么、下周可以改进的点。
///
/// 由 LLM 生成，失败时回退到 [WeeklySummary] 的本地规则文案。
class WeeklyNarrative {
  final String happened;
  final String improvement;

  const WeeklyNarrative({required this.happened, required this.improvement});
}
