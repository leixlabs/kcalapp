import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/diary_providers.dart';
import '../../../application/meal_review_controller.dart';
import '../../../domain/meal.dart';
import '../../../domain/meal_review.dart';
import '../../../domain/meal_type.dart';

/// 展示某个餐次的完整营养评价与组成食物。
Future<void> showMealReviewSheet(
  BuildContext context, {
  required MealType mealType,
  required DateTime date,
  required List<Meal> meals,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        MealReviewSheet(mealType: mealType, date: date, meals: meals),
  );
}

class MealReviewSheet extends ConsumerWidget {
  final MealType mealType;
  final DateTime date;
  final List<Meal> meals;

  const MealReviewSheet({
    super.key,
    required this.mealType,
    required this.date,
    required this.meals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewAsync = ref.watch(
      mealReviewProvider(mealReviewKey(date, mealType)),
    );
    final review = reviewAsync.valueOrNull;
    final foodCount = meals.fold<int>(0, (sum, m) => sum + m.foodItems.length);
    final totalKcal = meals.fold<double>(
      0,
      (sum, m) => sum + m.totalNutrition.kcal,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, review, foodCount, totalKcal),
            const SizedBox(height: 12),
            _buildReviewBody(theme, review, foodCount),
            const SizedBox(height: 20),
            _buildFoods(theme),
            const SizedBox(height: 20),
            _buildFooter(context, ref, review),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    MealReview? review,
    int foodCount,
    double totalKcal,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(mealType.icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mealType.label}营养评价',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '共 ${totalKcal.round()} kcal · $foodCount 项食物',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Text(
          'AI 生成',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBody(ThemeData theme, MealReview? review, int foodCount) {
    final content = review?.content;
    final status = review?.status;

    if (status == MealReviewStatus.refreshing) {
      return _statusBox(
        theme,
        icon: Icons.sync,
        text: content ?? '正在根据 $foodCount 项食物更新评价…',
      );
    }
    if (status == MealReviewStatus.failed && content == null) {
      return _statusBox(theme, icon: Icons.error_outline, text: '评价生成失败');
    }
    if (content == null || content.isEmpty) {
      return _statusBox(theme, icon: Icons.auto_awesome, text: '暂未生成评价');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _statusBox(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoods(ThemeData theme) {
    final foods = <Widget>[];
    for (final meal in meals) {
      for (final item in meal.foodItems) {
        foods.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.name, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${item.weightG.round()}g · ${item.kcal.round()} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (foods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '组成食物',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ...foods,
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, MealReview? review) {
    final status = review?.status;

    // 有内容或正在刷新时，不额外展示重新生成按钮。
    if (status != MealReviewStatus.failed && review?.content != null) {
      return const SizedBox.shrink();
    }
    if (status == MealReviewStatus.refreshing) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {
              ref.read(mealReviewControllerProvider).refresh(date, mealType);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新生成'),
          ),
        ),
      ],
    );
  }
}
