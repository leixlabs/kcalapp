import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/meal.dart';
import '../../domain/food_item.dart';
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
                child: Icon(Icons.arrow_back,
                    size: 18, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black26,
                  child: Icon(Icons.delete_outline,
                      size: 18, color: Colors.white),
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
                      errorBuilder: (_, __, ___) =>
                          Container(color: theme.colorScheme.surfaceContainerHighest),
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
                        child: Text(
                          meal.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal.mealType.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── 时间 ─────────────────────────────────────────────
                  Text(
                    FormatUtils.formatDate(meal.dateTime) +
                        '  ' +
                        FormatUtils.formatTime(meal.dateTime),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 20),

                  // ── 热量大字 ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _bigStat(
                          context,
                          label: '热量',
                          value: nutrition.kcal.round().toString(),
                          unit: 'kcal',
                          color: theme.colorScheme.primary,
                        ),
                        _bigStat(
                          context,
                          label: '碳水',
                          value: _fmtG(nutrition.carbsG),
                          unit: 'g',
                          color: AppColors.carbs,
                        ),
                        _bigStat(
                          context,
                          label: '蛋白质',
                          value: _fmtG(nutrition.proteinG),
                          unit: 'g',
                          color: AppColors.protein,
                        ),
                        _bigStat(
                          context,
                          label: '脂肪',
                          value: _fmtG(nutrition.fatG),
                          unit: 'g',
                          color: AppColors.fat,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 食材列表标题 ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '食材  (kcal)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (meal.servings != 1.0)
                        Text(
                          '× ${meal.servings} 份',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
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
                    horizontal: 16, vertical: 12),
                child: Text(
                  '暂无食材信息',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _FoodItemRow(
                  item: meal.foodItems[i],
                  isLast: i == meal.foodItems.length - 1,
                ),
                childCount: meal.foodItems.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // ── 底部：修改按钮 ────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () {
              context.push('/meal-editor?id=${meal.id}');
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('修改'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
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
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtG(double v) =>
      v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
}

// ─── 食材行组件 ────────────────────────────────────────────────────────────────

class _FoodItemRow extends StatelessWidget {
  final FoodItem item;
  final bool isLast;

  const _FoodItemRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // 食材名
                Expanded(
                  flex: 3,
                  child: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                // 重量
                Text(
                  '${_fmtG(item.weightG)}g',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(width: 12),
                // kcal
                SizedBox(
                  width: 64,
                  child: Text(
                    '${item.kcal.round()} kcal',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
        ],
      ),
    );
  }

  String _fmtG(double v) =>
      v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
}
