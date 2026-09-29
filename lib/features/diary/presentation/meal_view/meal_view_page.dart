import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/ruler_value_picker.dart';
import '../../domain/meal.dart';
import '../../domain/food_item.dart';
import '../../domain/meal_type.dart';
import '../../application/diary_providers.dart';

class MealViewPage extends ConsumerStatefulWidget {
  final String? mealId;

  const MealViewPage({super.key, this.mealId});

  @override
  ConsumerState<MealViewPage> createState() => _MealViewPageState();
}

class _MealViewPageState extends ConsumerState<MealViewPage> {
  Meal? _meal;
  bool _isLoading = true;

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条饮食记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(mealRepositoryProvider);
      await repo.softDeleteMeal(_meal!.id!);
      ref.invalidate(dailySummaryProvider);
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
        appBar: AppBar(title: const Text('记录详情')),
        body: const Center(child: Text('记录不存在')),
      );
    }

    final meal = _meal!;
    final theme = Theme.of(context);
    final nutrition = meal.totalNutrition;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── 顶部大图 / 占位 ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: meal.photoPath != null ? 240 : 0,
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
                tooltip: '删除',
                onPressed: _deleteMeal,
              ),
            ],
            flexibleSpace: meal.photoPath != null
                ? FlexibleSpaceBar(
                    background: Image.file(
                      File(meal.photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
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
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    meal.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
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
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: (type) {
                          if (type != null) {
                            setState(
                              () => _meal = meal.copyWith(mealType: type),
                            );
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
                                '总热量',
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
                              label: '碳水',
                              value: _fmtG(nutrition.carbsG),
                              unit: 'g',
                              color: AppColors.carbs,
                              onTap: () =>
                                  _editNutrient(_EditableNutrient.carbs),
                            ),
                            _bigStat(
                              context,
                              label: '蛋白质',
                              value: _fmtG(nutrition.proteinG),
                              unit: 'g',
                              color: AppColors.protein,
                              onTap: () =>
                                  _editNutrient(_EditableNutrient.protein),
                            ),
                            _bigStat(
                              context,
                              label: '脂肪',
                              value: _fmtG(nutrition.fatG),
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
                  _buildNutritionReview(meal, theme),
                  const SizedBox(height: 20),

                  // ── 食材列表标题 ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '食材 (kcal)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '点击食材修改名字和卡路里',
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
                  '暂无食材信息',
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ── 底部：在当前详情页确认修改 ───────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saveChanges,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('更新'),
          ),
        ),
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

  Widget _buildNutritionReview(Meal meal, ThemeData theme) {
    final review = meal.nutritionReview?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
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
              Text(
                '营养师评价',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'AI 生成',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review == null || review.isEmpty ? '暂无营养师评价' : review,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: review == null || review.isEmpty
                  ? theme.colorScheme.outline
                  : theme.colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrients(Meal meal, ThemeData theme) {
    const priority = [
      Mineral.calcium,
      Mineral.sodium,
      Mineral.iron,
      Mineral.magnesium,
    ];
    final minerals =
        [
              ...priority,
              ...Mineral.values.where((mineral) => !priority.contains(mineral)),
            ]
            .where(
              (mineral) => meal.foodItems.any(
                (item) => item.getMineral(mineral) != null,
              ),
            )
            .toList();
    final vitamins = Vitamin.values
        .where(
          (vitamin) =>
              meal.foodItems.any((item) => item.getVitamin(vitamin) != null),
        )
        .toList();
    if (minerals.isEmpty && vitamins.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '营养物质 (mg/μg)',
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
                  label: mineral.label,
                  value: _sumKnownValues(values) * meal.servings,
                  unit: mineral.unit,
                  onTap: () => _editMicronutrient(
                    mineral.label,
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
              '维生素',
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
                  label: vitamin.fullLabel,
                  value: perServing * meal.servings,
                  unit: vitamin.unit,
                  onTap: () => _editMicronutrient(
                    vitamin.fullLabel,
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
    final controller = TextEditingController(text: meal.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改餐名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '餐名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true && mounted && controller.text.trim().isNotEmpty) {
      setState(() => _meal = meal.copyWith(name: controller.text.trim()));
    }
    controller.dispose();
  }

  Future<void> _editFoodItem(int index) async {
    final meal = _meal!;
    final item = meal.foodItems[index];
    final nameController = TextEditingController(text: item.name);
    final kcalController = TextEditingController(
      text: item.kcal.toStringAsFixed(0),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改食材'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '食材名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalController,
              decoration: const InputDecoration(labelText: '热量 (kcal)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final kcal = double.tryParse(kcalController.text);
      final name = nameController.text.trim();
      if (kcal == null || kcal < 0 || name.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请填写有效的食材名称和热量')));
      } else {
        final items = [...meal.foodItems];
        items[index] = item.copyWith(name: name, kcal: kcal);
        setState(() => _meal = meal.copyWith(foodItems: items));
      }
    }
    nameController.dispose();
    kcalController.dispose();
  }

  void _removeFoodItem(int index) {
    final meal = _meal!;
    final items = [...meal.foodItems]..removeAt(index);
    setState(() => _meal = meal.copyWith(foodItems: items));
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
      _EditableNutrient.kcal => '热量',
      _EditableNutrient.carbs => '碳水',
      _EditableNutrient.protein => '蛋白质',
      _EditableNutrient.fat => '脂肪',
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
    if (changed != null && mounted) _scaleNutrient(nutrient, changed);
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
                Text('修改$label', style: Theme.of(ctx).textTheme.headlineSmall),
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
                    child: const Text('保存'),
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

  void _scaleNutrient(_EditableNutrient nutrient, double targetPerServing) {
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
    setState(() => _meal = meal.copyWith(foodItems: items));
  }

  Future<void> _editMicronutrient(
    String label,
    String unit,
    double currentValue,
    ValueChanged<double> onSave,
  ) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改$label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: '含量 ($unit)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      final value = double.tryParse(controller.text);
      if (value == null || value < 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请输入有效的营养素含量')));
      } else {
        onSave(value);
      }
    }
    controller.dispose();
  }

  void _scaleMineral(Mineral mineral, double targetPerServing) {
    _scaleMicronutrient(
      targetPerServing,
      (item, values) => item.copyWith(minerals: values),
      (item) => item.getMineral(mineral),
      (item) => item.minerals,
      (values, value) => values[mineral.index] = value,
      Mineral.values.length,
    );
  }

  void _scaleVitamin(Vitamin vitamin, double targetPerServing) {
    _scaleMicronutrient(
      targetPerServing,
      (item, values) => item.copyWith(vitamins: values),
      (item) => item.getVitamin(vitamin),
      (item) => item.vitamins,
      (values, value) => values[vitamin.index] = value,
      Vitamin.values.length,
    );
  }

  void _scaleMicronutrient(
    double targetPerServing,
    FoodItem Function(FoodItem, List<double?>) copyWithValues,
    double? Function(FoodItem) getValue,
    List<double?>? Function(FoodItem) getValues,
    void Function(List<double?>, double) setValue,
    int listLength,
  ) {
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
    setState(() => _meal = meal.copyWith(foodItems: items));
  }

  Future<void> _saveChanges() async {
    final meal = _meal;
    if (meal == null || meal.id == null) return;
    try {
      await ref
          .read(mealRepositoryProvider)
          .updateMeal(meal.copyWith(updatedAt: DateTime.now()));
      ref.invalidate(dailySummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已更新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('更新失败: $error')));
      }
    }
  }

  String _fmtG(double v) =>
      v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
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
                  tooltip: '删除食材',
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
