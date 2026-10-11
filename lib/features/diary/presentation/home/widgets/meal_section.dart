import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/meal_photo.dart';
import '../../../../../core/widgets/tap_delight.dart';
import '../../../../../l10n/l10n.dart';
import '../../../domain/meal.dart';
import '../../../domain/meal_review.dart';
import '../../../domain/meal_type.dart';
import 'meal_review_sheet.dart';

class MealSection extends StatelessWidget {
  final MealType mealType;
  final List<Meal> meals;
  final DateTime selectedDate;
  final ValueChanged<Meal>? onRetryRecognition;
  final MealReview? review;

  const MealSection({
    super.key,
    required this.mealType,
    required this.meals,
    required this.selectedDate,
    this.onRetryRecognition,
    this.review,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeMeals = meals.where((m) => m.mealType == mealType).toList();

    if (typeMeals.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalKcal = typeMeals.fold(
      0.0,
      (sum, m) => sum + m.totalNutrition.kcal,
    );
    final totalWeight = typeMeals.fold(0.0, (sum, m) => sum + m.totalWeightG);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 餐次标题行 ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      mealType.icon,
                      size: 22,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mealTypeLabel(context.l10n, mealType),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                TapDelight(
                  emojis: TapDelight.foodEmojis,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${totalKcal.round()}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: ' kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        TextSpan(
                          text: context.l10n.mealSectionApproxWeight,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        TextSpan(
                          text: '${totalWeight.round()}g',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MealReviewSummary(
              review: review,
              mealType: mealType,
              date: selectedDate,
              meals: typeMeals,
            ),
            // ── 每条记录 ────────────────────────────────────────────────
            ...typeMeals.map(
              (meal) =>
                  _MealItem(meal: meal, onRetryRecognition: onRetryRecognition),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealReviewSummary extends StatelessWidget {
  final MealReview? review;
  final MealType mealType;
  final DateTime date;
  final List<Meal> meals;

  const _MealReviewSummary({
    this.review,
    required this.mealType,
    required this.date,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = review?.status;
    final content = review?.content;
    final isRefreshing = status == MealReviewStatus.refreshing;
    final isFailed = status == MealReviewStatus.failed;
    final foodCount = meals.fold<int>(0, (sum, m) => sum + m.foodItems.length);

    if (content == null && !isRefreshing && !isFailed) {
      return const SizedBox.shrink();
    }

    final String text;
    if (isRefreshing) {
      text = content ?? context.l10n.mealReviewUpdating(foodCount);
    } else if (isFailed) {
      text = content ?? context.l10n.mealSectionReviewFailed;
    } else {
      text = content!;
    }

    return InkWell(
      onTap: () => showMealReviewSheet(
        context,
        mealType: mealType,
        date: date,
        meals: meals,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
            if (isRefreshing) ...[
              const SizedBox(width: 6),
              Text(
                context.l10n.mealSectionUpdating,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ] else if (status == MealReviewStatus.completed) ...[
              const SizedBox(width: 6),
              Text(
                context.l10n.mealSectionBasedOn(foodCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 单条记录 ──────────────────────────────────────────────────────────────────

class _MealItem extends StatefulWidget {
  final Meal meal;
  final ValueChanged<Meal>? onRetryRecognition;

  const _MealItem({required this.meal, this.onRetryRecognition});

  @override
  State<_MealItem> createState() => _MealItemState();
}

class _MealItemState extends State<_MealItem> {
  final GlobalKey _thumbnailKey = GlobalKey();

  Offset? _tapPosition;

  void _onTap() {
    final meal = widget.meal;
    final position = _tapPosition;
    final renderObject =
        _thumbnailKey.currentContext?.findRenderObject() as RenderBox?;
    if (meal.aiRecognitionStatus == AiRecognitionStatus.failed &&
        position != null &&
        renderObject != null) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      if ((topLeft & renderObject.size).contains(position)) {
        widget.onRetryRecognition?.call(meal);
        return;
      }
    }
    context.push('/meal-view?id=${meal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 食物种类：用食材名列表，最多展示 3 个
    final meal = widget.meal;
    final ingredientNames = meal.foodItems.map((i) => i.name).toList();
    final categoryText = switch (meal.aiRecognitionStatus) {
      AiRecognitionStatus.processing => context.l10n.mealSectionRecognizing,
      AiRecognitionStatus.failed => context.l10n.mealSectionRecognitionFailed,
      _ =>
        ingredientNames.isEmpty
            ? mealTypeLabel(context.l10n, meal.mealType)
            : ingredientNames.length <= 3
            ? ingredientNames.join(' · ')
            : context.l10n.mealSectionMoreFoods(
                ingredientNames.take(3).join(' · '),
              ),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onTapDown: (details) => _tapPosition = details.globalPosition,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // ── 图片 ──────────────────────────────────────────────────
            _MealThumbnail(
              key: _thumbnailKey,
              assetId: meal.photoAssetId,
              photoPath: meal.photoPath,
              aiRecognitionStatus: meal.aiRecognitionStatus,
            ),
            const SizedBox(width: 12),
            // ── 名称 + 食物种类 ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    categoryText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── 重量 + kcal ───────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${meal.totalNutrition.kcal.round()}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'kcal',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.mealSectionApproxGrams(
                    '${meal.totalWeightG.round()}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 缩略图组件 ────────────────────────────────────────────────────────────────

class _MealThumbnail extends StatelessWidget {
  final String? assetId;
  final String? photoPath;
  final AiRecognitionStatus aiRecognitionStatus;

  const _MealThumbnail({
    super.key,
    this.assetId,
    this.photoPath,
    required this.aiRecognitionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MealPhoto(
            assetId: assetId,
            path: photoPath,
            thumbSize: 240,
            placeholder: _placeholder(theme),
          ),
          if (aiRecognitionStatus == AiRecognitionStatus.processing)
            ColoredBox(
              color: Colors.black38,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (aiRecognitionStatus == AiRecognitionStatus.failed)
            ColoredBox(
              color: Colors.black38,
              child: Icon(Icons.refresh, color: Colors.white, size: 26),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Icon(
      Icons.restaurant,
      size: 28,
      color: theme.colorScheme.outline.withValues(alpha: 0.5),
    );
  }
}
