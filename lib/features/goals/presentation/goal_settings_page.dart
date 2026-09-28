import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../diary/domain/daily_goal.dart';
import '../../../app/providers.dart';

class GoalSettingsPage extends ConsumerStatefulWidget {
  const GoalSettingsPage({super.key});

  @override
  ConsumerState<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends ConsumerState<GoalSettingsPage> {
  final _kcalController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  void _loadGoal() async {
    final repo = ref.read(goalRepositoryProvider);
    final goal = await repo.getGoalForDate(DateTime.now());
    if (goal != null) {
      _kcalController.text = goal.kcal.toString();
      _carbsController.text = goal.carbsG.toString();
      _proteinController.text = goal.proteinG.toString();
      _fatController.text = goal.fatG.toString();
    } else {
      _kcalController.text = DailyGoal.recommendedKcal.toString();
      _carbsController.text = DailyGoal.recommendedCarbsG.toString();
      _proteinController.text = DailyGoal.recommendedProteinG.toString();
      _fatController.text = DailyGoal.recommendedFatG.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('目标设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每日热量与营养素目标', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _kcalController,
                      decoration: const InputDecoration(labelText: '热量目标 (kcal)', prefixIcon: Icon(Icons.local_fire_department)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: '碳水 (g)', prefixIcon: Icon(Icons.grain)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proteinController,
                      decoration: const InputDecoration(labelText: '蛋白质 (g)', prefixIcon: Icon(Icons.fitness_center)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: '脂肪 (g)', prefixIcon: Icon(Icons.water_drop)),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _resetToDefaults,
              child: const Text('恢复推荐默认值'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '目标自设置日起生效，不会覆盖过去日期的历史统计。',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saveGoal,
            child: const Text('保存目标'),
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _kcalController.text = DailyGoal.recommendedKcal.toString();
      _carbsController.text = DailyGoal.recommendedCarbsG.toString();
      _proteinController.text = DailyGoal.recommendedProteinG.toString();
      _fatController.text = DailyGoal.recommendedFatG.toString();
    });
  }

  void _saveGoal() async {
    final kcal = double.tryParse(_kcalController.text);
    final carbs = double.tryParse(_carbsController.text);
    final protein = double.tryParse(_proteinController.text);
    final fat = double.tryParse(_fatController.text);

    if (kcal == null || kcal <= 0 || kcal > 10000) {
      _showError('请输入有效的热量值 (1-10000)');
      return;
    }
    if (carbs == null || carbs < 0 || protein == null || protein < 0 || fat == null || fat < 0) {
      _showError('营养素不能为负数');
      return;
    }

    final goal = DailyGoal(
      effectiveDate: DateTime.now(),
      kcal: kcal,
      carbsG: carbs,
      proteinG: protein,
      fatG: fat,
    );

    final repo = ref.read(goalRepositoryProvider);
    await repo.saveGoal(goal);
    if (mounted) context.pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
