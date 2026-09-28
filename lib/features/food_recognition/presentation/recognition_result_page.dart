import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../diary/application/diary_providers.dart';
import '../../diary/domain/food_item.dart';
import '../../diary/domain/meal.dart';
import '../../diary/domain/meal_draft.dart';
import '../../diary/domain/meal_type.dart';
import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/states.dart';
import '../../../core/utils/format_utils.dart';

final recognitionDraftProvider = StateProvider<MealDraft?>((ref) => null);

class RecognitionResultPage extends ConsumerStatefulWidget {
  const RecognitionResultPage({super.key});

  @override
  ConsumerState<RecognitionResultPage> createState() => _RecognitionResultPageState();
}

class _RecognitionResultPageState extends ConsumerState<RecognitionResultPage> {
  late TextEditingController _nameController;
  late double _servings;
  late MealType _mealType;
  late List<FoodItem> _foodItems;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(recognitionDraftProvider);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    if (draft != null) {
      _nameController = TextEditingController(text: draft.mealName);
      _servings = draft.servings;
      _mealType = draft.mealType;
      _foodItems = List.from(draft.foodItems);
    } else {
      _nameController = TextEditingController();
      _servings = 1.0;
      _mealType = MealType.guessFromHour(DateTime.now().hour);
      _foodItems = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(recognitionDraftProvider);

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 识别结果')),
        body: EmptyState(
          title: '暂无识别结果',
          subtitle: '请先拍照识别餐食',
          icon: Icons.camera_alt_outlined,
          onAction: () => context.go('/'),
          actionLabel: '返回首页',
        ),
      );
    }

    final theme = Theme.of(context);
    final totalKcal = _foodItems.fold(0.0, (sum, item) => sum + item.kcal) * _servings;
    final totalCarbs = _foodItems.fold(0.0, (sum, item) => sum + item.carbsG) * _servings;
    final totalProtein = _foodItems.fold(0.0, (sum, item) => sum + item.proteinG) * _servings;
    final totalFat = _foodItems.fold(0.0, (sum, item) => sum + item.fatG) * _servings;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text('AI 识别结果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 照片
            if (draft.photoTempPath != null && File(draft.photoTempPath!).existsSync())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(draft.photoTempPath!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Meal name + meal type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'meal name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<MealType>(
                      value: _mealType,
                      underline: const SizedBox(),
                      isDense: true,
                      items: MealType.values.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label, style: theme.textTheme.bodyMedium),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _mealType = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Date picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${FormatUtils.formatDateShort(_selectedDate)} ${FormatUtils.formatTime(_selectedDate)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // 热量 + 份数
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.local_fire_department, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${totalKcal.round()}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    ' kcal',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const Spacer(),
                  _buildServingsStepper(theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 三大营养素
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutritionItem(theme, '碳水', '${totalCarbs.toStringAsFixed(1)}g', AppColors.carbs),
                    _buildNutritionItem(theme, '蛋白质', '${totalProtein.toStringAsFixed(1)}g', AppColors.protein),
                    _buildNutritionItem(theme, '脂肪', '${totalFat.toStringAsFixed(1)}g', AppColors.fat),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 食材
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('食材 (kcal)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '点击食材修改名字和卡路里',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _foodItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildIngredientChip(theme, item, index);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // AI 提示
            if (draft.notes != null && draft.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.aiEstimate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.aiEstimate),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          draft.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.aiEstimate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme, draft),
    );
  }

  Widget _buildServingsStepper(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () {
              if (_servings > 0.5) {
                setState(() => _servings -= 0.5);
              }
            },
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              _servings % 1 == 0 ? '${_servings.toInt()}' : '${_servings}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () {
              setState(() => _servings += 0.5);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(ThemeData theme, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIngredientChip(ThemeData theme, FoodItem item, int index) {
    return GestureDetector(
      onTap: () => _editIngredient(index),
      child: Chip(
        label: Text('${item.name} ${item.kcal.round()}kcal'),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () {
          setState(() => _foodItems.removeAt(index));
        },
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _editIngredient(int index) {
    final item = _foodItems[index];
    final nameController = TextEditingController(text: item.name);
    final kcalController = TextEditingController(text: item.kcal.round().toString());

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改食材'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '食材名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kcalController,
              decoration: const InputDecoration(labelText: '热量 (kcal)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newKcal = double.tryParse(kcalController.text) ?? item.kcal;
              setState(() {
                _foodItems[index] = item.copyWith(
                  name: nameController.text.trim().isEmpty ? item.name : nameController.text.trim(),
                  kcal: newKcal,
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, MealDraft draft) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saveMeal,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('保存记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      firstDate: DateTime(2024, 1, 1),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
    );
    if (pickedTime == null) return;
    if (mounted) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _saveMeal() async {
    final totalKcal = _foodItems.fold(0.0, (sum, item) => sum + item.kcal);
    if (totalKcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('kcal must be > 0')));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('meal name required')));
      return;
    }

    final now = DateTime.now();
    final meal = Meal(
      dateTime: _selectedDate,
      mealType: _mealType,
      name: _nameController.text.trim(),
      photoPath: ref.read(recognitionDraftProvider)?.photoTempPath,
      servings: _servings,
      source: 'ai',
      foodItems: _foodItems,
      createdAt: now,
      updatedAt: now,
    );

    final repo = ref.read(mealRepositoryProvider);
    try {
      await repo.saveMeal(meal);
      ref.read(recognitionDraftProvider.notifier).state = null;
      ref.invalidate(dailySummaryProvider);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
