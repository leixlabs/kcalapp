import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../app/providers.dart';
import '../../../../core/utils/format_utils.dart';
import '../../application/diary_providers.dart';
import '../../domain/food_item.dart';
import '../../domain/meal.dart';
import '../../domain/meal_type.dart';
import '../../domain/nutrition.dart';

class MealEditorPage extends ConsumerStatefulWidget {
  final String? mealId;
  final String? dateStr;
  final String? mealTypeStr;

  const MealEditorPage({
    super.key,
    this.mealId,
    this.dateStr,
    this.mealTypeStr,
  });

  @override
  ConsumerState<MealEditorPage> createState() => _MealEditorPageState();
}

class _MealEditorPageState extends ConsumerState<MealEditorPage> {
  final _nameController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final List<FoodItemEditor> _editors = [];
  MealType _mealType = MealType.breakfast;
  late DateTime _selectedDate;
  bool _isLoading = true;
  Meal? _existingMeal;

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDateStr(widget.dateStr);
    _mealType = MealType.fromString(widget.mealTypeStr);
    _loadData();
  }

  void _loadData() async {
    if (widget.mealId != null) {
      final repo = ref.read(mealRepositoryProvider);
      final meal = await repo.getMealById(int.parse(widget.mealId!));
      if (meal != null && mounted) {
        _existingMeal = meal;
        _nameController.text = meal.name;
        _servingsController.text = meal.servings.toString();
        _mealType = meal.mealType;
        _selectedDate = meal.dateTime;
        _editors.clear();
        for (final item in meal.foodItems) {
          _editors.add(FoodItemEditor.fromFoodItem(item));
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  DateTime _parseDateStr(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      final parts = dateStr.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    for (final e in _editors) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));

    final servings = double.tryParse(_servingsController.text) ?? 1.0;
    final totalNutrition = _calculateTotal(servings);

    return Scaffold(
      appBar: AppBar(title: Text(_existingMeal != null ? '编辑餐食' : '添加餐食')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealInfoSection(theme),
            const SizedBox(height: 16),
            _buildNutritionSummary(theme, totalNutrition),
            const SizedBox(height: 16),
            _buildFoodItemsSection(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, theme, servings, totalNutrition),
    );
  }

  Widget _buildMealInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '餐名'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MealType>(
                    value: _mealType,
                    decoration: const InputDecoration(labelText: '餐次'),
                    items: MealType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setState(() => _mealType = v ?? _mealType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _servingsController,
                    decoration: const InputDecoration(labelText: '份数'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
           ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 20),
              title: Text(FormatUtils.formatDate(_selectedDate), style: theme.textTheme.bodyMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(ThemeData theme, Nutrition total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('热量', '${total.kcal.round()}', 'kcal', theme.colorScheme.primary),
          _summaryItem('碳水', total.carbsDisplay, 'g', AppColors.carbs),
          _summaryItem('蛋白质', total.proteinDisplay, 'g', AppColors.protein),
          _summaryItem('脂肪', total.fatDisplay, 'g', AppColors.fat),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, String unit, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(unit, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }

  Widget _buildFoodItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('食材', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _addFoodItem,
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ],
        ),
        ..._editors.asMap().entries.map((entry) {
          final i = entry.key;
          final editor = entry.value;
          return _FoodItemCard(
            editor: editor,
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _editors.removeAt(i)),
          );
        }),
        if (_editors.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('暂无食材，点击添加', style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              )),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme, double servings, Nutrition total) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_editors.isNotEmpty)
              Text('合计 ${total.kcal.round()} kcal', style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
            const Spacer(),
            FilledButton.icon(
              onPressed: _editors.isEmpty ? null : _saveMeal,
              icon: const Icon(Icons.check),
              label: Text(_existingMeal != null ? '更新记录' : '保存记录'),
            ),
          ],
        ),
      ),
    );
  }

  void _addFoodItem() {
    setState(() {
      _editors.add(FoodItemEditor());
    });
  }

  Nutrition _calculateTotal(double servings) {
    if (_editors.isEmpty) return Nutrition.zero;
    var total = Nutrition.zero;
    for (final editor in _editors) {
      final nutrition = editor.nutrition;
      if (nutrition != null) {
        total = total + nutrition;
      }
    }
    return total.scaledByServings(servings);
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveMeal() async {
    final servings = double.tryParse(_servingsController.text) ?? 1.0;
    if (servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('份数必须大于 0')));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入餐名')));
      return;
    }

    final foodItems = _editors.map((e) => e.toFoodItem()).toList();
    final now = DateTime.now();

    final meal = Meal(
      id: _existingMeal?.id,
      dateTime: _selectedDate,
      mealType: _mealType,
      name: _nameController.text.trim(),
      servings: servings,
      source: _existingMeal?.source ?? 'manual',
      foodItems: foodItems,
      createdAt: _existingMeal?.createdAt ?? now,
      updatedAt: now,
    );

    final repo = ref.read(mealRepositoryProvider);
    try {
      if (_existingMeal != null) {
        await repo.updateMeal(meal);
      } else {
        await repo.saveMeal(meal);
      }
      if (mounted) {
        ref.invalidate(dailySummaryProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}

class FoodItemEditor {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController kcalController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fatController = TextEditingController();

  FoodItemEditor();

  FoodItemEditor.fromFoodItem(FoodItem item) {
    nameController.text = item.name;
    weightController.text = item.weightG.toString();
    kcalController.text = item.kcal.toString();
    carbsController.text = item.carbsG.toString();
    proteinController.text = item.proteinG.toString();
    fatController.text = item.fatG.toString();
  }

  void dispose() {
    nameController.dispose();
    weightController.dispose();
    kcalController.dispose();
    carbsController.dispose();
    proteinController.dispose();
    fatController.dispose();
  }

  Nutrition? get nutrition {
    final kcal = double.tryParse(kcalController.text);
    final carbs = double.tryParse(carbsController.text);
    final protein = double.tryParse(proteinController.text);
    final fat = double.tryParse(fatController.text);
    if (kcal == null || carbs == null || protein == null || fat == null) return null;
    return Nutrition(kcal: kcal, carbsG: carbs, proteinG: protein, fatG: fat);
  }

  FoodItem toFoodItem() {
    return FoodItem(
      name: nameController.text.trim().isEmpty ? '食材' : nameController.text.trim(),
      weightG: double.tryParse(weightController.text) ?? 0,
      kcal: double.tryParse(kcalController.text) ?? 0,
      carbsG: double.tryParse(carbsController.text) ?? 0,
      proteinG: double.tryParse(proteinController.text) ?? 0,
      fatG: double.tryParse(fatController.text) ?? 0,
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItemEditor editor;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _FoodItemCard({
    required this.editor,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: editor.nameController,
                    decoration: const InputDecoration(labelText: '食材名', isDense: true),
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildField(editor.weightController, '重量(g)'),
                const SizedBox(width: 8),
                _buildField(editor.kcalController, '热量'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildField(editor.carbsController, '碳水(g)'),
                const SizedBox(width: 8),
                _buildField(editor.proteinController, '蛋白(g)'),
                const SizedBox(width: 8),
                _buildField(editor.fatController, '脂肪(g)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
        keyboardType: TextInputType.number,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
