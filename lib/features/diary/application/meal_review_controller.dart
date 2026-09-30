import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/llm/llm_adapter.dart';
import '../domain/meal_review.dart';
import '../domain/meal_type.dart';
import 'diary_providers.dart';

/// 餐次级营养评价的后台生成与失效。
///
/// 评价归属于「日期 + 餐次」，基于该餐次下全部已保存食物的汇总。
/// 保存食物后由各调用方触发 [refresh]，不阻塞记录保存；首页营养汇总
/// 立即更新，评价随后在后台替换。
class MealReviewController {
  final Ref _ref;
  MealReviewController(this._ref);

  /// 重新生成某个餐次（日期 + 餐次）的评价。
  ///
  /// 先标记为刷新中并保留上一次评价内容（避免空白），随后在后台请求 LLM；
  /// 成功则原位替换，失败则保留旧内容并标记失败。
  Future<void> refresh(DateTime date, MealType mealType) async {
    final dao = _ref.read(mealReviewDaoProvider);
    final existing = await dao.get(date, mealType);

    await dao.upsert(
      MealReview(
        date: date,
        mealType: mealType,
        content: existing?.content,
        status: MealReviewStatus.refreshing,
        updatedAt: DateTime.now(),
      ),
    );
    _ref.invalidate(mealReviewProvider((date: date, mealType: mealType)));

    try {
      final profile = await _ref.read(llmProfileDaoProvider).getActive();
      final apiKey = profile == null
          ? null
          : await _ref.read(secureStoreProvider).read('${profile.id}');
      if (profile == null || apiKey == null || apiKey.isEmpty) {
        throw const MealReviewGenerationException('请先在设置中配置 LLM 服务');
      }

      final meals = await _ref.read(mealRepositoryProvider).getMealsByDate(date);
      final group = meals
          .where((m) => m.mealType == mealType && m.foodItems.isNotEmpty)
          .toList();

      if (group.isEmpty) {
        await dao.upsert(
          MealReview(
            date: date,
            mealType: mealType,
            content: null,
            status: MealReviewStatus.idle,
            updatedAt: DateTime.now(),
          ),
        );
        return;
      }

      final content = await _ref.read(llmAdapterProvider).reviewMeal(
        profile: profile,
        apiKey: apiKey,
        mealType: _toHint(mealType),
        meals: group,
      );
      await dao.upsert(
        MealReview(
          date: date,
          mealType: mealType,
          content: content,
          status: MealReviewStatus.completed,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      await dao.upsert(
        MealReview(
          date: date,
          mealType: mealType,
          content: existing?.content,
          status: MealReviewStatus.failed,
          updatedAt: DateTime.now(),
        ),
      );
    } finally {
      _ref.invalidate(mealReviewProvider((date: date, mealType: mealType)));
    }
  }

  /// 便捷入口：按餐食 id 触发其所属餐次的评价刷新。
  Future<void> refreshForMeal(int mealId) async {
    final meal = await _ref.read(mealRepositoryProvider).getMealById(mealId);
    if (meal == null) return;
    await refresh(meal.dateTime, meal.mealType);
  }

  MealTypeHint _toHint(MealType type) => MealTypeHint.values.firstWhere(
    (e) => e.name == type.name,
    orElse: () => MealTypeHint.snack,
  );
}

class MealReviewGenerationException implements Exception {
  final String message;
  const MealReviewGenerationException(this.message);
  @override
  String toString() => message;
}

final mealReviewControllerProvider = Provider<MealReviewController>((ref) {
  return MealReviewController(ref);
});
