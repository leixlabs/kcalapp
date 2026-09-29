import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../application/diary_providers.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/states.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/meal_section.dart';
import '../../domain/meal_type.dart';
import '../../../food_recognition/application/recognition_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      body: SafeArea(
        child: summaryAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorStateView(
            message: '加载失败: $e',
            onRetry: () => ref.invalidate(dailySummaryProvider),
          ),
          data: (summary) => CustomScrollView(
            slivers: [
              // 顶部 App Bar（logo + 日期选择器 + 头像）
              SliverToBoxAdapter(
                child: _buildAppBar(context, ref, selectedDate),
              ),
              // 本周日期横向视图
              SliverToBoxAdapter(
                child: _WeekDatePicker(
                  selectedDate: selectedDate,
                  onDateSelected: (d) =>
                      ref.read(selectedDateProvider.notifier).state = d,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              // 目标 + 半环 + 三大营养素 合并卡片
              SliverToBoxAdapter(
                child: _buildDailyGoalCard(context, summary),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // 今日饮食记录标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '今日饮食记录',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ..._buildMealSections(context, summary, selectedDate),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => _pickFromGalleryAndAnalyze(context, ref),
        child: FloatingActionButton.extended(
          onPressed: () => _takePhotoAndAnalyze(context, ref),
          icon: const Icon(Icons.camera_alt),
          label: const Text('拍照识别热量'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // 居中：日期选择下拉
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => context.push('/calendar'),
                child: Semantics(
                  label: '选择日期',
                  button: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          FormatUtils.formatDateChinese(selectedDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            size: 18, color: theme.colorScheme.onSurface),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 右侧：头像/设置
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/llm-settings'),
            child: Semantics(
              label: '设置',
              button: true,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person_outline,
                    size: 20, color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 目标卡片（半环 + 三大营养素）─────────────────────────────────────────

  Widget _buildDailyGoalCard(BuildContext context, dynamic summary) {
    final theme = Theme.of(context);
    final hasGoal = summary.goal != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：目标 kcal + 修改目标按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        hasGoal
                            ? '目标  ${summary.target!.kcal.round()} kcal'
                            : '未设置目标',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/goals'),
                    child: Row(
                      children: [
                        Text(
                          '修改目标',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.edit_outlined,
                            size: 14, color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 半环居中
              Center(
                child: CalorieRing(
                  consumed: summary.consumed.kcal,
                  target: summary.target?.kcal,
                  hasGoal: hasGoal,
                ),
              ),
              const SizedBox(height: 16),
              // 三大营养素进度
              _buildMacrosRow(context, summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacrosRow(BuildContext context, dynamic summary) {
    return Row(
      children: [
        _buildMacroItem(
          context: context,
          label: '碳水化合物',
          consumed: summary.consumed.carbsG,
          target: summary.target?.carbsG,
          color: AppColors.carbs,
        ),
        _buildMacroItem(
          context: context,
          label: '蛋白质',
          consumed: summary.consumed.proteinG,
          target: summary.target?.proteinG,
          color: AppColors.protein,
        ),
        _buildMacroItem(
          context: context,
          label: '脂肪',
          consumed: summary.consumed.fatG,
          target: summary.target?.fatG,
          color: AppColors.fat,
        ),
      ],
    );
  }

  Widget _buildMacroItem({
    required BuildContext context,
    required String label,
    required double consumed,
    required double? target,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final hasTarget = target != null && target > 0;
    final progress = hasTarget ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isOver = hasTarget && consumed > target;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatG(consumed),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
                if (hasTarget)
                  TextSpan(
                    text: ' / ${_formatG(target)}g',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  )
                else
                  TextSpan(
                    text: 'g',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasTarget ? progress : null,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(
                  isOver ? theme.colorScheme.error : color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatG(double? v) {
    if (v == null) return '0';
    return v >= 10 ? v.round().toString() : v.toStringAsFixed(1);
  }

  // ─── 餐食分区列表 ──────────────────────────────────────────────────────────

  List<Widget> _buildMealSections(BuildContext context, dynamic summary, DateTime selectedDate) {
    final sections = <Widget>[];
    for (final type in MealType.values) {
      final typeMeals =
          summary.meals.where((m) => m.mealType == type).toList();
      if (typeMeals.isNotEmpty) {
        sections.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: MealSection(
                mealType: type,
                meals: summary.meals,
                selectedDate: selectedDate,
              ),
            ),
          ),
        );
      }
    }
    if (sections.isEmpty) {
      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 48,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    '今日暂无饮食记录',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角拍照按钮开始记录',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return sections;
  }

  // ─── 拍照 / 识别逻辑 ───────────────────────────────────────────────────────

  void _takePhotoAndAnalyze(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(recognitionControllerProvider);
    if (!await controller.isLlmConfigured()) {
      if (!context.mounted) return;
      _showLlmMissingDialog(context);
      return;
    }
    final mealType = MealType.guessFromHour(DateTime.now().hour);
    final photo = await controller.takePhoto();
    if (photo == null || !context.mounted) return;
    await _runRecognition(context, controller, photo.path, mealType);
  }

  void _pickFromGalleryAndAnalyze(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(recognitionControllerProvider);
    if (!await controller.isLlmConfigured()) {
      if (!context.mounted) return;
      _showLlmMissingDialog(context);
      return;
    }
    final mealType = MealType.guessFromHour(DateTime.now().hour);
    final photo = await controller.pickFromGallery();
    if (photo == null || !context.mounted) return;
    await _runRecognition(context, controller, photo.path, mealType);
  }

  Future<void> _runRecognition(
    BuildContext context,
    RecognitionController controller,
    String photoPath,
    MealType mealType,
  ) async {
    final cancelToken = CancelToken();
    var dialogClosed = false;

    void closeDialog() {
      if (dialogClosed || !context.mounted) return;
      dialogClosed = true;
      Navigator.of(context, rootNavigator: true).pop();
    }

    _showRecognizingDialog(context, onCancel: () {
      if (!cancelToken.isCancelled) cancelToken.cancel('user_cancelled');
      closeDialog();
    }).then((_) => dialogClosed = true);
    await Future.delayed(const Duration(milliseconds: 50));
    if (cancelToken.isCancelled) return;

    try {
      await controller.recognize(photoPath,
          mealTypeHint: mealType, cancelToken: cancelToken);
      closeDialog();
      if (cancelToken.isCancelled) return;
      if (context.mounted) context.push('/recognition-result');
    } on RecognitionCancelledException {
      closeDialog();
    } catch (e) {
      closeDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showRecognizingDialog(BuildContext context,
      {required VoidCallback onCancel}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text('AI 识别中...'),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: onCancel, child: const Text('取消')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLlmMissingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未配置 LLM 服务'),
        content: const Text('AI 识别需要先在设置中添加 LLM 服务并填写 API Key。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/llm-settings');
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}

// ─── 本周日期选择器 ────────────────────────────────────────────────────────────

class _WeekDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekDatePicker({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 本周一
    final monday = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1));

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        itemBuilder: (ctx, i) {
          final day = monday.add(Duration(days: i));
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isToday = _isToday(day);
          const weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: Container(
              width: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isToday
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      fontWeight:
                          (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}
