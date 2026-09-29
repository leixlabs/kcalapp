import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/meal.dart';
import '../../../domain/meal_type.dart';

class MealSection extends StatelessWidget {
  final MealType mealType;
  final List<Meal> meals;
  final DateTime selectedDate;

  const MealSection({
    super.key,
    required this.mealType,
    required this.meals,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeMeals = meals.where((m) => m.mealType == mealType).toList();

    if (typeMeals.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalKcal =
        typeMeals.fold(0.0, (sum, m) => sum + m.totalNutrition.kcal);
    final totalWeight =
        typeMeals.fold(0.0, (sum, m) => sum + m.totalWeightG);

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
                    Icon(mealType.icon,
                        size: 22, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      mealType.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${totalWeight.round()}g',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '/',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      TextSpan(
                        text: '${totalKcal.round()}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── 每条记录 ────────────────────────────────────────────────
            ...typeMeals.map((meal) => _MealItem(meal: meal)),
          ],
        ),
      ),
    );
  }
}

// ─── 单条记录 ──────────────────────────────────────────────────────────────────

class _MealItem extends StatelessWidget {
  final Meal meal;

  const _MealItem({required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 食物种类：用食材名列表，最多展示 3 个
    final ingredientNames = meal.foodItems.map((i) => i.name).toList();
    final categoryText = ingredientNames.isEmpty
        ? meal.mealType.label
        : ingredientNames.length <= 3
            ? ingredientNames.join(' · ')
            : '${ingredientNames.take(3).join(' · ')} 等';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // 点击进查看页（Task 5 一起改）
      onTap: () => context.push('/meal-view?id=${meal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // ── 图片 ──────────────────────────────────────────────────
            _MealThumbnail(photoPath: meal.photoPath),
            const SizedBox(width: 12),
            // ── 名称 + 食物种类 ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    categoryText,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
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
                  '约${meal.totalWeightG.round()}g',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 18, color: theme.colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

// ─── 缩略图组件 ────────────────────────────────────────────────────────────────

class _MealThumbnail extends StatelessWidget {
  final String? photoPath;

  const _MealThumbnail({this.photoPath});

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
      child: photoPath != null
          ? Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(theme),
            )
          : _placeholder(theme),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Icon(
      Icons.restaurant,
      size: 28,
      color: theme.colorScheme.outline.withOpacity(0.5),
    );
  }
}
