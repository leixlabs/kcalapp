import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../diary/application/diary_providers.dart';
import '../../diary/domain/daily_goal.dart';
import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';

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
      appBar: AppBar(title: Text(context.l10n.goalsTitle)),
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
                    Text(context.l10n.goalsDailySection, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _kcalController,
                      decoration: InputDecoration(labelText: context.l10n.goalsCalorieTarget, prefixIcon: const Icon(Icons.local_fire_department)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _carbsController,
                      decoration: InputDecoration(labelText: context.l10n.goalsCarbsTarget, prefixIcon: const Icon(Icons.grain)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proteinController,
                      decoration: InputDecoration(labelText: context.l10n.goalsProteinTarget, prefixIcon: const Icon(Icons.fitness_center)),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fatController,
                      decoration: InputDecoration(labelText: context.l10n.goalsFatTarget, prefixIcon: const Icon(Icons.water_drop)),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _resetToDefaults,
              child: Text(context.l10n.goalsResetDefaults),
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
                        context.l10n.goalsNote,
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
            child: Text(context.l10n.goalsSave),
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
      _showError(context.l10n.goalsInvalidKcal);
      return;
    }
    if (carbs == null || carbs < 0 || protein == null || protein < 0 || fat == null || fat < 0) {
      _showError(context.l10n.goalsNegativeNutrient);
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
    if (mounted) {
      ref.invalidate(dailySummaryProvider);
      context.pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
