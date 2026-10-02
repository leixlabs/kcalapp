import 'package:flutter/material.dart';

import '../../../domain/food_category.dart';

/// 食物类别周进度。
///
/// 默认使用应用主题配色；通过 [labelColor]、[mutedColor]、[trackColor] 与
/// [categoryColor] 可在自定义配色的场景（例如分享卡片）中直接复用同一组件。
class FoodCategoryProgressCard extends StatelessWidget {
  final Map<FoodCategory, double> weeklyGrams;
  final Color? labelColor;
  final Color? mutedColor;
  final Color? trackColor;
  final Color Function(FoodCategory category)? categoryColor;

  /// 是否在底部展示数据来源说明；分享卡片中可关闭以保持简洁。
  final bool showNote;

  const FoodCategoryProgressCard({
    super.key,
    required this.weeklyGrams,
    this.labelColor,
    this.mutedColor,
    this.trackColor,
    this.categoryColor,
    this.showNote = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = FoodCategory.values
        .where((category) => category != FoodCategory.other)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          _CategoryProgressRow(
            category: categories[i],
            grams: weeklyGrams[categories[i]] ?? 0,
            labelColor: labelColor,
            mutedColor: mutedColor,
            trackColor: trackColor,
            categoryColor: categoryColor,
          ),
          if (i != categories.length - 1) const SizedBox(height: 14),
        ],
        if (showNote) ...[
          const SizedBox(height: 12),
          Text(
            '按食材名称和录入重量粗略归类；参考《中国居民膳食指南》成人日建议量折算为周目标，仅作饮食记录参考。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor ?? theme.colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  final FoodCategory category;
  final double grams;
  final Color? labelColor;
  final Color? mutedColor;
  final Color? trackColor;
  final Color Function(FoodCategory category)? categoryColor;

  const _CategoryProgressRow({
    required this.category,
    required this.grams,
    this.labelColor,
    this.mutedColor,
    this.trackColor,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = category.weeklyReferenceGrams;
    final progress = (grams / target).clamp(0.0, 1.0);
    final color =
        categoryColor?.call(category) ?? _defaultColor(category, theme);
    final secondary = mutedColor ?? theme.colorScheme.outline;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: labelColor,
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
                      color: secondary,
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
            backgroundColor:
                trackColor ?? theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Color _defaultColor(FoodCategory category, ThemeData theme) =>
      switch (category) {
        FoodCategory.grains => const Color(0xFFBF8D42),
        FoodCategory.vegetablesAndFruits => const Color(0xFF4D9A65),
        FoodCategory.meatEggsAndSeafood => const Color(0xFFD77A66),
        FoodCategory.dairyBeansAndNuts => theme.colorScheme.tertiary,
        FoodCategory.other => theme.colorScheme.outline,
      };
}
