import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/utils/format_utils.dart';
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

    final totalKcal = typeMeals.fold(0.0, (sum, m) => sum + m.totalNutrition.kcal);
    final totalWeight = typeMeals.fold(0.0, (sum, m) => sum + m.totalWeightG);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(mealType.icon, size: 20, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(mealType.label, style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
                Text(
                  '${totalWeight.round()}g/${totalKcal.round()}kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...typeMeals.map((meal) => _buildMealCard(context, meal)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    final theme = Theme.of(context);
    final isAiSource = meal.source == 'ai';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/meal-editor?id=${meal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: meal.photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        meal.photoPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 24),
                      ),
                    )
                  : const Icon(Icons.restaurant, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAiSource) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.aiEstimate.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('AI', style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.aiEstimate, fontSize: 10,
                          )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${FormatUtils.formatTime(meal.dateTime)} · ${meal.foodItems.length}种食材 · 约${meal.totalWeightG.round()}g',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.totalNutrition.kcal.round()}kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
