import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/weekly_review.dart';
import 'diary_providers.dart';
import 'weekly_summary.dart';

/// 周回顾的生成与持久化。
///
/// 一周只保留一条记录（按周起始日存储）。打开周回顾页时调用 [ensure]：若已存
/// 内容与当前记录指纹一致则直接复用、不重复请求；记录发生变化或尚无内容时才
/// 调用 LLM，并把结果落库。
class WeeklyReviewController {
  final Ref _ref;
  WeeklyReviewController(this._ref);

  Future<void> ensure(DateTime selectedDate) async {
    final meals = await _ref.read(weeklyMealsProvider(selectedDate).future);
    if (meals.isEmpty) return;

    final weekStart = weekStartFor(selectedDate);
    final dao = _ref.read(weeklyReviewDaoProvider);
    final signature = weeklyMealSignature(meals);
    final stored = await dao.get(weekStart);
    if (stored != null &&
        stored.signature == signature &&
        (stored.happened?.isNotEmpty ?? false)) {
      return;
    }

    try {
      final profile = await _ref.read(llmProfileDaoProvider).getActive();
      if (profile == null) return;
      final apiKey = await _ref.read(secureStoreProvider).read('${profile.id}');
      if (apiKey == null || apiKey.isEmpty) return;

      final narrative = await _ref
          .read(llmAdapterProvider)
          .summarizeWeek(
            profile: profile,
            apiKey: apiKey,
            weekStart: weekStart,
            meals: meals,
          );
      final improvement = narrative.improvement.isEmpty
          ? WeeklySummary(weekStart: weekStart, meals: meals).nextWeekFocus
          : narrative.improvement;
      await dao.upsert(
        WeeklyReview(
          weekStart: weekStart,
          happened: narrative.happened,
          improvement: improvement,
          signature: signature,
          updatedAt: DateTime.now(),
        ),
      );
      _ref.invalidate(weeklyReviewProvider(selectedDate));
    } catch (_) {
      // 静默失败：界面继续使用本地规则文案，下次打开会再尝试。
    }
  }

  /// 用户手动改写「饮食建议」时持久化。
  Future<void> editImprovement(
    DateTime selectedDate,
    String improvement,
  ) async {
    final weekStart = weekStartFor(selectedDate);
    final dao = _ref.read(weeklyReviewDaoProvider);
    final stored = await dao.get(weekStart);
    final meals = await _ref.read(weeklyMealsProvider(selectedDate).future);
    final summary = WeeklySummary(weekStart: weekStart, meals: meals);
    await dao.upsert(
      WeeklyReview(
        weekStart: weekStart,
        happened: stored?.happened ?? summary.happenedSummary,
        improvement: improvement,
        signature: stored != null && stored.signature.isNotEmpty
            ? stored.signature
            : weeklyMealSignature(meals),
        updatedAt: DateTime.now(),
      ),
    );
    _ref.invalidate(weeklyReviewProvider(selectedDate));
  }
}

final weeklyReviewControllerProvider = Provider<WeeklyReviewController>((ref) {
  return WeeklyReviewController(ref);
});
