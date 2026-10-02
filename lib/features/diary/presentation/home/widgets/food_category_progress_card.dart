import 'package:flutter/material.dart';

import '../../../domain/food_category.dart';

class FoodCategoryProgressCard extends StatelessWidget {
  final Map<FoodCategory, double> weeklyGrams;

  const FoodCategoryProgressCard({super.key, required this.weeklyGrams});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in FoodCategory.values.where(
          (category) => category != FoodCategory.other,
        )) ...[
          _CategoryProgressRow(
            category: category,
            grams: weeklyGrams[category] ?? 0,
          ),
          if (category != FoodCategory.dairyBeansAndNuts)
            const SizedBox(height: 14),
        ],
        const SizedBox(height: 12),
        Text(
          '按食材名称和录入重量粗略归类；参考《中国居民膳食指南》成人日建议量折算为周目标，仅作饮食记录参考。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  final FoodCategory category;
  final double grams;

  const _CategoryProgressRow({required this.category, required this.grams});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = category.weeklyReferenceGrams;
    final progress = (grams / target).clamp(0.0, 1.0);
    final color = _categoryColor(category, theme);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${grams.round()}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: ' / ${target.round()} g',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Color _categoryColor(FoodCategory category, ThemeData theme) =>
      switch (category) {
        FoodCategory.grains => const Color(0xFFBF8D42),
        FoodCategory.vegetablesAndFruits => const Color(0xFF4D9A65),
        FoodCategory.meatEggsAndSeafood => const Color(0xFFD77A66),
        FoodCategory.dairyBeansAndNuts => theme.colorScheme.tertiary,
        FoodCategory.other => theme.colorScheme.outline,
      };
}
