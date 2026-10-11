import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/meal_photo.dart';
import '../../../../core/widgets/ruler_value_picker.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/meal.dart';
import '../../domain/food_item.dart';
import '../../domain/meal_type.dart';
import '../../application/diary_providers.dart';
import '../../domain/meal_review.dart';
import '../../application/meal_review_controller.dart';
import '../home/widgets/meal_review_sheet.dart';

class MealViewPage extends ConsumerStatefulWidget {
  final String? mealId;

  const MealViewPage({super.key, this.mealId});

  @override
  ConsumerState<MealViewPage> createState() => _MealViewPageState();
}

class _MealViewPageState extends ConsumerState<MealViewPage> {
  Meal? _meal;
  bool _isLoading = true;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    if (widget.mealId != null) {
      final repo = ref.read(mealRepositoryProvider);
      final meal = await repo.getMealById(int.parse(widget.mealId!));
      if (mounted) {
        setState(() {
          _meal = meal;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeal() async {
    if (_meal?.id == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealViewDeleteTitle),
        content: Text(l10n.mealViewDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(mealRepositoryProvider);
      final meal = _meal;
      await repo.softDeleteMeal(_meal!.id!);
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(weeklyMealsProvider);
      if (meal != null) {
        unawaited(
          ref
              .read(mealReviewControllerProvider)
              .refresh(meal.dateTime, meal.mealType, context.l10n),
        );
      }
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_meal == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.mealViewTitle)),
        body: Center(child: Text(context.l10n.mealViewNotFound)),
      );
    }

    final meal = _meal!;
    final theme = Theme.of(context);
    final nutrition = meal.totalNutrition;
    final hasPhoto =
        (meal.photoAssetId?.isNotEmpty ?? false) ||
        (meal.photoPath?.isNotEmpty ?? false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── 顶部大图 / 占位 ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: hasPhoto ? 240 : 0,
            pinned: true,
            leading: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, size: 18, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black26,
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                tooltip: context.l10n.actionDelete,
                onPressed: _deleteMeal,
              ),
            ],
            flexibleSpace: hasPhoto
                ? FlexibleSpaceBar(
                    background: MealPhoto(
                      assetId: meal.photoAssetId,
                      path: meal.photoPath,
                      thumbSize: 900,
                      placeholder: Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  )
                : null,
            backgroundColor: theme.colorScheme.surface,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 标题行：名称 + 餐次标签 ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _editMealName,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              meal.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<MealType>(
                        value: meal.mealType,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        borderRadius: BorderRadius.circular(12),
                        items: MealType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(mealTypeLabel(context.l10n, type)),
                              ),
                            )
                            .toList(),
                        onChanged: (type) {
                          if (type != null) {
                            _updateMeal(meal.copyWith(mealType: type));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── 时间 ─────────────────────────────────────────────
                  Text(
                    '${FormatUtils.formatDate(meal.dateTime)}  ${FormatUtils.formatTime(meal.dateTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 营养摘要：点击数值可直接修改 ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _editNutrient(_EditableNutrient.kcal),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: theme.colorScheme.error,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.mealViewTotalCalories,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${nutrition.kcal.round()}',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'kcal',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _bigStat(
                              context,
                              label: context.l10n.macroCarbs,
                              value: FormatUtils.formatGramValue(
                                nutrition.carbsG,
                              ),
                              unit: 'g',
                              color: AppColors.carbs,
                              onTap: () =>
                                  _editNutrient(_EditableNutrient.carbs),
                            ),
                            _bigStat(
                              context,
                              label: context.l10n.macroProtein,
                              value: FormatUtils.formatGramValue(
                                nutrition.proteinG,
                              ),
                              unit: 'g',
                              color: AppColors.protein,
                              onTap: () =>
                                  _editNutrient(_EditableNutrient.protein),
                            ),
                            _bigStat(
                              context,
                              label: context.l10n.macroFat,
                              value: FormatUtils.formatGramValue(
                                nutrition.fatG,
                              ),
                              unit: 'g',
                              color: AppColors.fat,
                              onTap: () => _editNutrient(_EditableNutrient.fat),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMealReviewLink(meal, theme),
                  const SizedBox(height: 20),

                  // ── 食材列表标题 ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.mealViewFoodsKcal,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.l10n.mealViewFoodsHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── 食材条目列表 ──────────────────────────────────────────────
          if (meal.foodItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  context.l10n.mealViewNoFoods,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _FoodItemRow(
                  item: meal.foodItems[i],
                  onTap: () => _editFoodItem(i),
                  onDelete: () => _removeFoodItem(i),
                ),
                childCount: meal.foodItems.length,
              ),
            ),

          if (meal.foodItems.any(
            (item) => item.minerals != null || item.vitamins != null,
          ))
            SliverToBoxAdapter(child: _buildMicronutrients(meal, theme)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _bigStat(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 22,
              height: 2,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealReviewLink(Meal meal, ThemeData theme) {
    final l10n = context.l10n;
    final reviewAsync = ref.watch(
      mealReviewProvider(mealReviewKey(meal.dateTime, meal.mealType)),
    );
    final allMeals =
        ref.watch(mealsByDateProvider(meal.dateTime)).valueOrNull ?? const [];
    final group = allMeals.where((m) => m.mealType == meal.mealType).toList();
    final totalKcal = group.fold<double>(
      0,
      (sum, m) => sum + m.totalNutrition.kcal,
    );
    final review = reviewAsync.valueOrNull;
    final content = review?.content;

    final String hint;
    if (review?.status == MealReviewStatus.refreshing) {
      final foodCount = group.fold<int>(
        0,
        (sum, m) => sum + m.foodItems.length,
      );
      hint = content ?? l10n.mealReviewUpdating(foodCount);
    } else if (review?.status == MealReviewStatus.failed && content == null) {
      hint = l10n.mealSectionReviewFailed;
    } else if (content != null && content.isNotEmpty) {
      hint = content;
    } else {
      hint = l10n.mealViewReviewWillUseAll(
        mealTypeLabel(context.l10n, meal.mealType),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showMealReviewSheet(
          context,
          mealType: meal.mealType,
          date: meal.dateTime,
          meals: group,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.mealViewCountedIn(
                      mealTypeLabel(context.l10n, meal.mealType),
                      totalKcal.round().toString(),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: content != null && content.isNotEmpty
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.mealViewViewFullReview,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicronutrients(Meal meal, ThemeData theme) {
    final minerals = coreMinerals
        .where(
          (mineral) =>
              meal.foodItems.any((item) => item.getMineral(mineral) != null),
        )
        .where(
          (mineral) =>
              _sumKnownValues(
                    meal.foodItems.map((item) => item.getMineral(mineral)),
                  ) *
                  meal.servings >=
              0.05,
        )
        .toList();
    final vitamins = coreVitamins
        .where(
          (vitamin) =>
              meal.foodItems.any((item) => item.getVitamin(vitamin) != null),
        )
        .where(
          (vitamin) =>
              _sumKnownValues(
                    meal.foodItems.map((item) => item.getVitamin(vitamin)),
                  ) *
                  meal.servings >=
              0.05,
        )
        .toList();
    if (minerals.isEmpty && vitamins.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mealViewNutrients,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (minerals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMicronutrientGrid(
              theme,
              minerals.map((mineral) {
                final values = meal.foodItems.map(
                  (item) => item.getMineral(mineral),
                );
                return _MicronutrientValue(
                  label: mineralLabel(context.l10n, mineral),
                  value: _sumKnownValues(values) * meal.servings,
                  unit: mineral.unit,
                  onTap: () => _editMicronutrient(
                    mineralLabel(context.l10n, mineral),
                    mineral.unit,
                    _sumKnownValues(
                      meal.foodItems.map((item) => item.getMineral(mineral)),
                    ),
                    (value) => _scaleMineral(mineral, value),
                  ),
                );
              }).toList(),
            ),
          ],
          if (vitamins.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.recognitionVitamins,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            _buildMicronutrientGrid(
              theme,
              vitamins.map((vitamin) {
                final perServing = _sumKnownValues(
                  meal.foodItems.map((item) => item.getVitamin(vitamin)),
                );
                return _MicronutrientValue(
                  label: vitamin.fullLabel(context.l10n),
                  value: perServing * meal.servings,
                  unit: vitamin.unit,
                  onTap: () => _editMicronutrient(
                    vitamin.fullLabel(context.l10n),
                    vitamin.unit,
                    perServing,
                    (value) => _scaleVitamin(vitamin, value),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicronutrientGrid(
    ThemeData theme,
    List<_MicronutrientValue> values,
  ) {
    final width = (MediaQuery.of(context).size.width - 52) / 3;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((entry) {
        return InkWell(
          onTap: entry.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: width,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  entry.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatMicronutrient(entry.value)} ${entry.unit}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  double _sumKnownValues(Iterable<double?> values) =>
      values.whereType<double>().fold(0, (sum, value) => sum + value);

  String _formatMicronutrient(double value) {
    if (value < 0.05) return '0';
    return value >= 10 ? value.round().toString() : value.toStringAsFixed(1);
  }

  Future<void> _editMealName() async {
    final meal = _meal!;
    final l10n = context.l10n;
    final controller = TextEditingController(text: meal.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealViewEditMealName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.mealViewMealName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved == true && mounted && controller.text.trim().isNotEmpty) {
      await _updateMeal(meal.copyWith(name: controller.text.trim()));
    }
    controller.dispose();
  }

  Future<void> _editFoodItem(int index) async {
    final meal = _meal!;
    final l10n = context.l10n;
    final item = meal.foodItems[index];
    final nameController = TextEditingController(text: item.name);
    final kcalController = TextEditingController(
      text: item.kcal.toStringAsFixed(0),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealViewEditFood),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.mealViewFoodName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalController,
              decoration: InputDecoration(labelText: l10n.recognitionKcalLabel),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final kcal = double.tryParse(kcalController.text);
      final name = nameController.text.trim();
      if (kcal == null || kcal < 0 || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealViewInvalidFood)),
        );
      } else {
        final items = [...meal.foodItems];
        items[index] = item.copyWith(name: name, kcal: kcal);
        await _updateMeal(meal.copyWith(foodItems: items));
      }
    }
    nameController.dispose();
    kcalController.dispose();
  }

  Future<void> _removeFoodItem(int index) async {
    final meal = _meal!;
    final items = [...meal.foodItems]..removeAt(index);
    await _updateMeal(meal.copyWith(foodItems: items));
  }

  Future<void> _editNutrient(_EditableNutrient nutrient) async {
    final meal = _meal!;
    final nutrition = meal.totalNutrition;
    final currentValue = switch (nutrient) {
      _EditableNutrient.kcal => nutrition.kcal / meal.servings,
      _EditableNutrient.carbs => nutrition.carbsG / meal.servings,
      _EditableNutrient.protein => nutrition.proteinG / meal.servings,
      _EditableNutrient.fat => nutrition.fatG / meal.servings,
    };
    final label = switch (nutrient) {
      _EditableNutrient.kcal => context.l10n.nutrientCalories,
      _EditableNutrient.carbs => context.l10n.macroCarbs,
      _EditableNutrient.protein => context.l10n.macroProtein,
      _EditableNutrient.fat => context.l10n.macroFat,
    };
    final color = switch (nutrient) {
      _EditableNutrient.kcal => Theme.of(context).colorScheme.primary,
      _EditableNutrient.carbs => AppColors.carbs,
      _EditableNutrient.protein => AppColors.protein,
      _EditableNutrient.fat => AppColors.fat,
    };
    final unit = nutrient == _EditableNutrient.kcal ? 'kcal' : 'g';
    final maxValue = (currentValue * 2 + 100).clamp(
      100.0,
      nutrient == _EditableNutrient.kcal ? 3000.0 : 500.0,
    );
    final changed = await _showNutrientSlider(
      label,
      unit,
      color,
      currentValue,
      maxValue,
    );
    if (changed != null && mounted) {
      await _scaleNutrient(nutrient, changed);
    }
  }

  Future<double?> _showNutrientSlider(
    String label,
    String unit,
    Color color,
    double currentValue,
    double maxValue,
  ) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var value = currentValue.clamp(0.0, maxValue);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              top: 26,
            ).add(const EdgeInsets.symmetric(horizontal: 24)),
            decoration: const BoxDecoration(
              color: Color(0xFFF5FAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.editValue(label),
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                RulerValuePicker(
                  value: value,
                  max: maxValue,
                  step: unit == 'kcal' ? 1 : 0.1,
                  unit: unit,
                  color: color,
                  onChanged: (next) => setSheetState(() => value = next),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.pop(ctx, value),
                    child: Text(context.l10n.actionSave),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scaleNutrient(
    _EditableNutrient nutrient,
    double targetPerServing,
  ) async {
    final meal = _meal!;
    if (meal.foodItems.isEmpty) return;
    double valueFor(FoodItem item) => switch (nutrient) {
      _EditableNutrient.kcal => item.kcal,
      _EditableNutrient.carbs => item.carbsG,
      _EditableNutrient.protein => item.proteinG,
      _EditableNutrient.fat => item.fatG,
    };
    final oldTotal = meal.foodItems.fold<double>(
      0,
      (sum, item) => sum + valueFor(item),
    );
    final items = meal.foodItems.map((item) {
      final share = oldTotal > 0
          ? valueFor(item) / oldTotal
          : 1 / meal.foodItems.length;
      final value = targetPerServing * share;
      return switch (nutrient) {
        _EditableNutrient.kcal => item.copyWith(kcal: value),
        _EditableNutrient.carbs => item.copyWith(carbsG: value),
        _EditableNutrient.protein => item.copyWith(proteinG: value),
        _EditableNutrient.fat => item.copyWith(fatG: value),
      };
    }).toList();
    await _updateMeal(meal.copyWith(foodItems: items));
  }

  Future<void> _editMicronutrient(
    String label,
    String unit,
    double currentValue,
    Future<void> Function(double) onSave,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editValue(label)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.mealViewContentLabel(unit)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final value = double.tryParse(controller.text);
      if (value == null || value < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealViewInvalidNutrient)),
        );
      } else {
        await onSave(value);
      }
    }
    controller.dispose();
  }

  Future<void> _scaleMineral(Mineral mineral, double targetPerServing) {
    return _scaleMicronutrient(
      targetPerServing,
      (item, values) => item.copyWith(minerals: values),
      (item) => item.getMineral(mineral),
      (item) => item.minerals,
      (values, value) => values[mineral.index] = value,
      Mineral.values.length,
    );
  }

  Future<void> _scaleVitamin(Vitamin vitamin, double targetPerServing) {
    return _scaleMicronutrient(
      targetPerServing,
      (item, values) => item.copyWith(vitamins: values),
      (item) => item.getVitamin(vitamin),
      (item) => item.vitamins,
      (values, value) => values[vitamin.index] = value,
      Vitamin.values.length,
    );
  }

  Future<void> _scaleMicronutrient(
    double targetPerServing,
    FoodItem Function(FoodItem, List<double?>) copyWithValues,
    double? Function(FoodItem) getValue,
    List<double?>? Function(FoodItem) getValues,
    void Function(List<double?>, double) setValue,
    int listLength,
  ) async {
    final meal = _meal!;
    final oldTotal = _sumKnownValues(meal.foodItems.map(getValue));
    final items = meal.foodItems.map((item) {
      final values = List<double?>.from(
        getValues(item) ?? List<double?>.filled(listLength, null),
      );
      final share = oldTotal > 0
          ? (getValue(item) ?? 0) / oldTotal
          : 1 / meal.foodItems.length;
      setValue(values, targetPerServing * share);
      return copyWithValues(item, values);
    }).toList();
    await _updateMeal(meal.copyWith(foodItems: items));
  }

  Future<void> _updateMeal(Meal updatedMeal) {
    if (updatedMeal.id == null) return Future<void>.value();
    _saveQueue = _saveQueue.then((_) async {
      final previous = _meal;
      final mealToSave = updatedMeal.copyWith(updatedAt: DateTime.now());
      try {
        await ref.read(mealRepositoryProvider).updateMeal(mealToSave);
        if (!mounted) return;
        setState(() => _meal = mealToSave);
        ref.invalidate(dailySummaryProvider);
        ref.invalidate(weeklyMealsProvider);
        _refreshReviewsAfterEdit(previous, mealToSave);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.mealViewSaveFailed('$error'))),
          );
        }
      }
    });
    return _saveQueue;
  }

  void _refreshReviewsAfterEdit(Meal? previous, Meal current) {
    final l10n = context.l10n;
    final controller = ref.read(mealReviewControllerProvider);
    final keys = <({DateTime date, MealType mealType})>{};
    if (previous != null) {
      keys.add((date: previous.dateTime, mealType: previous.mealType));
    }
    keys.add((date: current.dateTime, mealType: current.mealType));
    for (final key in keys) {
      unawaited(controller.refresh(key.date, key.mealType, l10n));
    }
  }
}

// ─── 食材行组件 ────────────────────────────────────────────────────────────────

class _FoodItemRow extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FoodItemRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(item.name, style: theme.textTheme.bodyMedium),
                ),
                SizedBox(
                  width: 78,
                  child: Text(
                    '${item.kcal.round()}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.mealViewDeleteFood,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EditableNutrient { kcal, carbs, protein, fat }

class _MicronutrientValue {
  final String label;
  final double value;
  final String unit;
  final VoidCallback onTap;

  const _MicronutrientValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
  });
}
