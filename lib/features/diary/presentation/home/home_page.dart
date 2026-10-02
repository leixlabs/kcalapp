import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme.dart';
import '../../application/diary_providers.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/states.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/meal_section.dart';
import '../../domain/meal.dart';
import '../../domain/meal_type.dart';
import '../../../food_recognition/application/recognition_controller.dart';
import '../calendar/calendar_page.dart';
import 'widgets/food_category_progress_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isCalendarExpanded = false;
  bool _isWeeklyFoodCategoryExpanded = true;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = FormatUtils.isToday(selectedDate);
    final weekKcal =
        ref.watch(weeklyKcalProvider(selectedDate)).valueOrNull ?? const {};

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
              // 顶部 App Bar（logo + 日期选择器 + 设置按钮）
              SliverToBoxAdapter(child: _buildAppBar(context, selectedDate)),
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isCalendarExpanded
                      ? CalendarDrawer(
                          selectedDate: selectedDate,
                          focusedDay: _focusedDay,
                          onFocusedDayChanged: (day) =>
                              setState(() => _focusedDay = day),
                          onDateSelected: (day) {
                            ref.read(selectedDateProvider.notifier).state = day;
                            setState(() {
                              _focusedDay = day;
                              _isCalendarExpanded = false;
                            });
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // 本周日期横向视图（含每日 kcal）
              SliverToBoxAdapter(
                child: _WeekDatePicker(
                  selectedDate: selectedDate,
                  kcalByDay: weekKcal,
                  onDateSelected: (day) {
                    ref.read(selectedDateProvider.notifier).state = day;
                    if (day.year != _focusedDay.year ||
                        day.month != _focusedDay.month) {
                      setState(() => _focusedDay = day);
                    }
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              // 目标 + 半环 + 三大营养素 合并卡片
              SliverToBoxAdapter(child: _buildDailyGoalCard(context, summary)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildProgressSection(context, summary, selectedDate),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // 当日饮食记录标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isToday
                        ? '今日饮食记录'
                        : '${FormatUtils.formatDateShort(selectedDate)}饮食记录',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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

  Widget _buildAppBar(BuildContext context, DateTime selectedDate) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Position independently of the trailing settings button so the
            // selected date stays centered in the full app bar.
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                    if (_isCalendarExpanded) _focusedDay = selectedDate;
                  });
                },
                child: Semantics(
                  label: '选择日期',
                  button: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
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
                        AnimatedRotation(
                          turns: _isCalendarExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/llm-settings'),
                child: Semantics(
                  label: '设置',
                  button: true,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 每日热量目标卡片 ──────────────────────────────────────────────────────

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '今日热量',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/goals'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasGoal
                                ? '目标 ${summary.target!.kcal.round()}'
                                : '设置目标',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (hasGoal) ...[
                            const SizedBox(width: 3),
                            Text(
                              'kcal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: CalorieRing(
                  consumed: summary.consumed.kcal,
                  target: summary.target?.kcal,
                  hasGoal: hasGoal,
                ),
              ),
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
          label: '碳水',
          consumed: summary.consumed.carbsG,
          target: summary.target?.carbsG,
          color: AppColors.carbs,
          icon: Icons.grain,
        ),
        const SizedBox(width: 12),
        _buildMacroItem(
          context: context,
          label: '蛋白质',
          consumed: summary.consumed.proteinG,
          target: summary.target?.proteinG,
          color: AppColors.protein,
          icon: Icons.egg_outlined,
        ),
        const SizedBox(width: 12),
        _buildMacroItem(
          context: context,
          label: '脂肪',
          consumed: summary.consumed.fatG,
          target: summary.target?.fatG,
          color: AppColors.fat,
          icon: Icons.water_drop_outlined,
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    dynamic summary,
    DateTime selectedDate,
  ) {
    final theme = Theme.of(context);
    final weekStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).subtract(Duration(days: selectedDate.weekday - 1));

    final nextMonday = weekStart.add(const Duration(days: 7));
    final weeklyProgress = ref.watch(
      weeklyFoodCategoryProgressProvider(selectedDate),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日营养素进度',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMacrosRow(context, summary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              maintainState: true,
              leading: Icon(
                Icons.calendar_view_week,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                '食物类别 · 本周',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${weekStart.month}/${weekStart.day}–${nextMonday.subtract(const Duration(days: 1)).month}/${nextMonday.subtract(const Duration(days: 1)).day}',
              ),
              onExpansionChanged: (expanded) =>
                  setState(() => _isWeeklyFoodCategoryExpanded = expanded),
              initiallyExpanded: _isWeeklyFoodCategoryExpanded,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                weeklyProgress.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '本周食物类别加载失败：$error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  data: (weeklyGrams) =>
                      FoodCategoryProgressCard(weeklyGrams: weeklyGrams),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  context.push('/weekly-summary', extra: selectedDate),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('本周总结'),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required BuildContext context,
    required String label,
    required double consumed,
    required double? target,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final hasTarget = target != null && target > 0;
    final progress = hasTarget ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      FormatUtils.formatGramValue(consumed),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'g',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hasTarget
                  ? '目标 ${FormatUtils.formatGramValue(target)} g'
                  : '未设目标',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: hasTarget ? progress : 0,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 餐食分区列表 ──────────────────────────────────────────────────────────

  List<Widget> _buildMealSections(
    BuildContext context,
    dynamic summary,
    DateTime selectedDate,
  ) {
    final sections = <Widget>[];
    for (final type in MealType.values) {
      final typeMeals = summary.meals.where((m) => m.mealType == type).toList();
      if (typeMeals.isNotEmpty) {
        sections.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: MealSection(
                mealType: type,
                meals: summary.meals,
                selectedDate: selectedDate,
                review: ref
                    .watch(
                      mealReviewProvider(mealReviewKey(selectedDate, type)),
                    )
                    .valueOrNull,
                onRetryRecognition: (meal) {
                  final photoPath = meal.photoPath;
                  if (meal.id != null && photoPath != null) {
                    unawaited(
                      _processRecognition(
                        ScaffoldMessenger.of(context),
                        ref.read(recognitionControllerProvider),
                        meal.id!,
                        photoPath,
                        meal.mealType,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        );
      }
    }
    if (sections.isEmpty) {
      sections.add(
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.restaurant_menu,
            title: FormatUtils.isToday(selectedDate) ? '今日暂无饮食记录' : '该日暂无饮食记录',
            subtitle: '点击右下角按钮拍照识别，添加一条饮食记录',
          ),
        ),
      );
    }
    return sections;
  }

  // ─── 拍照 / 识别逻辑 ───────────────────────────────────────────────────────

  void _takePhotoAndAnalyze(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(recognitionControllerProvider);
    final mealType = MealType.guessFromHour(DateTime.now().hour);
    final photo = await controller.takePhoto();
    if (photo == null || !context.mounted) return;
    await _runRecognition(context, controller, photo.path, mealType);
  }

  void _pickFromGalleryAndAnalyze(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(recognitionControllerProvider);
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
    final messenger = ScaffoldMessenger.of(context);
    String? savedPhotoPath;
    try {
      final savedPhoto = await ref
          .read(imageProcessorProvider)
          .saveMealPhoto(photoPath);
      savedPhotoPath = savedPhoto.path;
      final persistedPhotoPath = savedPhoto.path;
      final now = DateTime.now();
      final mealId = await ref
          .read(mealRepositoryProvider)
          .saveMeal(
            Meal(
              dateTime: now,
              mealType: mealType,
              name: 'AI 识别中',
              photoPath: persistedPhotoPath,
              source: 'ai',
              aiRecognitionStatus: AiRecognitionStatus.processing,
              createdAt: now,
              updatedAt: now,
            ),
          );
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(weeklyMealsProvider);
      unawaited(
        _processRecognition(
          messenger,
          controller,
          mealId,
          persistedPhotoPath,
          mealType,
        ),
      );
    } catch (e) {
      if (savedPhotoPath != null) {
        await ref.read(imageProcessorProvider).deleteFile(savedPhotoPath);
      }
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('保存饮食记录失败：$e')));
      }
    }
  }

  Future<void> _processRecognition(
    ScaffoldMessengerState messenger,
    RecognitionController controller,
    int mealId,
    String photoPath,
    MealType mealType,
  ) async {
    try {
      await controller.recognizeSavedMeal(
        mealId,
        photoPath: photoPath,
        mealType: mealType,
      );
    } catch (e) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('AI 识别失败，记录已保留，可双击图片重试')),
        );
      }
    }
  }
}

// ─── 本周日期选择器 ────────────────────────────────────────────────────────────

class _WeekDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, double> kcalByDay;

  const _WeekDatePicker({
    required this.selectedDate,
    required this.onDateSelected,
    this.kcalByDay = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 本周一
    final monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        itemBuilder: (ctx, i) {
          final day = monday.add(Duration(days: i));
          final dayKey = DateTime(day.year, day.month, day.day);
          final isSelected =
              day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isToday = FormatUtils.isToday(day);
          final kcal = kcalByDay[dayKey] ?? 0;
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
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 40,
                    height: 12,
                    child: kcal > 0
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              kcal.round().toString(),
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
