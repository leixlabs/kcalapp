import 'package:flutter/material.dart';

import '../../../../../app/theme.dart';
import '../../../../../core/utils/format_utils.dart';
import '../../../domain/nutrition.dart';

class NutritionProgressCard extends StatelessWidget {
  final Nutrition consumed;
  final Nutrition? target;

  const NutritionProgressCard({super.key, required this.consumed, this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _macroItem(
              context: context,
              label: '碳水',
              consumed: consumed.carbsG,
              target: target?.carbsG,
              color: AppColors.carbs,
              icon: Icons.grain,
            ),
            _divider(),
            _macroItem(
              context: context,
              label: '蛋白质',
              consumed: consumed.proteinG,
              target: target?.proteinG,
              color: AppColors.protein,
              icon: Icons.egg_outlined,
            ),
            _divider(),
            _macroItem(
              context: context,
              label: '脂肪',
              consumed: consumed.fatG,
              target: target?.fatG,
              color: AppColors.fat,
              icon: Icons.water_drop_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroItem({
    required BuildContext context,
    required String label,
    required double consumed,
    required double? target,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final hasTarget = target != null && target > 0;
    final progress = hasTarget ? (consumed / target!).clamp(0.0, 1.0) : 0.0;
    final isOver = hasTarget && consumed > target!;

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: FormatUtils.formatGrams(consumed).replaceAll(' g', ''),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOver
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: hasTarget
                      ? ' / ${FormatUtils.formatGrams(target!).replaceAll(' g', '')}'
                      : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                TextSpan(
                  text: ' g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasTarget ? progress : null,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(
                isOver ? theme.colorScheme.error : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.withOpacity(0.15),
    );
  }
}
