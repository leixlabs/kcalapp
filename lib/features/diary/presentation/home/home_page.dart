import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../application/diary_providers.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/states.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/nutrition_progress_card.dart';
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
          error: (e, _) => ErrorStateView(message: '加载失败: $e', onRetry: () => ref.invalidate(dailySummaryProvider)),
          data: (summary) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, ref, selectedDate),
              ),
              SliverToBoxAdapter(
                child: _buildGoalCard(context, summary),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: NutritionProgressCard(
                  consumed: summary.consumed,
                  target: summary.target,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _buildRemainingCard(context, summary),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ..._buildMealSections(summary, selectedDate),
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

  List<Widget> _buildMealSections(dynamic summary, DateTime selectedDate) {
    final sections = <Widget>[];
    for (final type in MealType.values) {
      final typeMeals = summary.meals.where((m) => m.mealType == type).toList();
      if (typeMeals.isNotEmpty) {
        // 注意：CustomScrollView 的 slivers 列表只接受 sliver 组件，
        // 普通 box 组件必须用 SliverToBoxAdapter 包裹，否则渲染时崩溃。
        sections.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
                  Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    '今日暂无饮食记录',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角拍照按钮开始记录',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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

  /// 拍照后直接唤起 AI 识别，不再经过预览页。
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

  /// 长按入口：从相册选择图片进行 AI 识别（便于测试验证）。
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

    // 等弹窗路由完成推入后再开始识别，避免 pop 误伤首页路由。
    _showRecognizingDialog(context, onCancel: () {
      if (!cancelToken.isCancelled) cancelToken.cancel('user_cancelled');
      closeDialog();
    }).then((_) => dialogClosed = true);
    await Future.delayed(const Duration(milliseconds: 50));
    if (cancelToken.isCancelled) return;

    try {
      await controller.recognize(
        photoPath,
        mealTypeHint: mealType,
        cancelToken: cancelToken,
      );
      closeDialog();
      // 用户已取消时不再跳转结果页
      if (cancelToken.isCancelled) return;
      if (context.mounted) {
        context.push('/recognition-result');
      }
    } on RecognitionCancelledException {
      closeDialog();
    } catch (e) {
      closeDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showRecognizingDialog(BuildContext context, {required VoidCallback onCancel}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
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
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            child: const Text('取消'),
          ),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      selectedDate.subtract(const Duration(days: 1));
                },
              ),
              GestureDetector(
                onTap: () => context.push('/calendar'),
                child: Column(
                  children: [
                    Text(FormatUtils.dayLabel(selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(FormatUtils.formatDate(selectedDate),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      selectedDate.add(const Duration(days: 1));
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, semanticLabel: '设置'),
            tooltip: '设置',
            onPressed: () => context.push('/llm-settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, dynamic summary) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CalorieRing(
                consumed: summary.consumed.kcal,
                target: summary.target?.kcal,
                hasGoal: summary.goal != null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary.goal != null) ...[
                      if (summary.remaining != null && summary.remaining!.kcal > 0)
                        _buildInfoRow(context, '剩余', '${summary.remaining!.kcal.round()} kcal', theme.colorScheme.primary)
                      else if (summary.remaining != null)
                        _buildInfoRow(context, '已超', '${(-summary.remaining!.kcal).round()} kcal', theme.colorScheme.error),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, '已摄入', '${summary.consumed.kcal.round()} kcal', theme.colorScheme.onSurface),
                      const SizedBox(height: 4),
                      _buildInfoRow(context, '目标', '${summary.target!.kcal.round()} kcal', theme.colorScheme.outline),
                    ] else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('未设置目标', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('点击设置每日热量目标', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => GoRouter.of(context).push('/goals'),
                            child: const Text('设置目标'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildRemainingCard(BuildContext context, dynamic summary) {
    if (summary.goal == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final remaining = summary.remaining;
    if (remaining == null) return const SizedBox.shrink();
    final isOver = remaining.kcal < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: (isOver ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOver ? Icons.warning_amber : Icons.local_dining,
              size: 18, color: isOver ? theme.colorScheme.error : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              isOver
                  ? '已超出目标 ${(-remaining.kcal).round()} kcal'
                  : '还可摄入 ${remaining.kcal.round()} kcal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isOver ? theme.colorScheme.error : theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
