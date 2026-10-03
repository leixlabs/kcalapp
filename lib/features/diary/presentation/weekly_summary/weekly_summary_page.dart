import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/diary_providers.dart';
import '../../application/weekly_review_controller.dart';
import '../../application/weekly_summary.dart';
import '../../domain/daily_goal.dart';
import '../../domain/meal.dart';
import '../../domain/weekly_narrative.dart';
import '../../../../core/widgets/meal_photo.dart';
import '../../../../core/widgets/states.dart';
import 'widgets/weekly_summary_share_card.dart';

class WeeklySummaryPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const WeeklySummaryPage({super.key, required this.selectedDate});

  @override
  ConsumerState<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends ConsumerState<WeeklySummaryPage> {
  final _cardKey = GlobalKey();
  Future<void> _photosReady = Future<void>.value();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(weeklyReviewControllerProvider).ensure(widget.selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(weeklyMealsProvider(widget.selectedDate));
    final weekStart = weekStartFor(widget.selectedDate);
    final isCurrentWeek = weekStartFor(DateTime.now()) == weekStart;
    final periodEnd = isCurrentWeek
        ? DateTime.now()
        : weekStart.add(const Duration(days: 6));
    final hasMeals = mealsAsync.valueOrNull?.isNotEmpty ?? false;
    final stored = ref
        .watch(weeklyReviewProvider(widget.selectedDate))
        .valueOrNull;
    final hasStoredReview = stored?.happened?.isNotEmpty ?? false;
    final dailyKcalGoal =
        ref.watch(weeklyKcalGoalProvider(widget.selectedDate)).valueOrNull ??
        DailyGoal.recommendedKcal;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentWeek ? '本周回顾' : '周回顾'),
        actions: [
          if (hasMeals && hasStoredReview)
            IconButton(
              tooltip: '调整饮食建议',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editImprovement,
            ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: '周回顾加载失败：$error',
          onRetry: () =>
              ref.invalidate(weeklyMealsProvider(widget.selectedDate)),
        ),
        data: (meals) {
          final summary = WeeklySummary(weekStart: weekStart, meals: meals);
          final fallback = WeeklyNarrative(
            happened: summary.happenedSummary,
            improvement: summary.nextWeekFocus,
          );
          final happened = hasStoredReview
              ? stored!.happened!
              : fallback.happened;
          final improvement = (stored?.improvement?.isNotEmpty ?? false)
              ? stored!.improvement!
              : fallback.improvement;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: WeeklySummaryShareCard(
                  summary: summary,
                  periodEnd: periodEnd,
                  happened: happened,
                  improvement: improvement,
                  dailyKcalGoal: dailyKcalGoal,
                  onPhotosReady: (ready) => _photosReady = ready,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: _isSharing || !hasMeals
                  ? null
                  : () => _generateAndShare(buttonContext),
              icon: _isSharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              label: Text(_isSharing ? '正在生成…' : '生成图片保存'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editImprovement() async {
    final stored = ref
        .read(weeklyReviewProvider(widget.selectedDate))
        .valueOrNull;
    final meals =
        ref.read(weeklyMealsProvider(widget.selectedDate)).valueOrNull ??
        const <Meal>[];
    final summary = WeeklySummary(
      weekStart: weekStartFor(widget.selectedDate),
      meals: meals,
    );
    final current = (stored?.improvement?.isNotEmpty ?? false)
        ? stored!.improvement!
        : summary.nextWeekFocus;

    final controller = TextEditingController(text: current);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('调整饮食建议'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          maxLength: 60,
          decoration: const InputDecoration(labelText: '下周想改进什么？'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('应用'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || edited == null || edited.trim().isEmpty) return;
    await ref
        .read(weeklyReviewControllerProvider)
        .editImprovement(widget.selectedDate, edited.trim());
  }

  Future<void> _precachePhotos() async {
    final meals =
        ref.read(weeklyMealsProvider(widget.selectedDate)).valueOrNull ??
        const <Meal>[];
    final summary = WeeklySummary(
      weekStart: weekStartFor(widget.selectedDate),
      meals: meals,
    );
    final providers = summary.photoMeals
        .map(
          (meal) => MealPhotoProvider.maybe(
            assetId: meal.photoAssetId,
            path: meal.photoPath,
            thumbSize: WeeklySummaryShareCard.photoThumbSize,
          ),
        )
        .whereType<MealPhotoProvider>();
    for (final provider in providers) {
      try {
        await precacheImage(provider, context);
      } catch (_) {
        // 单张照片预热失败不阻塞导出；拼图会在预筛选时跳过不可读照片。
      }
    }
  }

  Future<void> _generateAndShare(BuildContext buttonContext) async {
    final shareBox = buttonContext.findRenderObject() as RenderBox?;
    final shareOrigin = shareBox != null && shareBox.hasSize
        ? shareBox.localToGlobal(Offset.zero) & shareBox.size
        : null;
    setState(() => _isSharing = true);
    try {
      // 等待可读照片筛选完成，避免把拼图加载指示器截进分享图片。
      await _photosReady;
      await _precachePhotos();
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('分享卡片尚未准备好');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError('无法生成分享图片');

      final weekStart = weekStartFor(widget.selectedDate);
      final imageFile = File(
        '${Directory.systemTemp.path}/weekly-summary-${weekStart.year}-${weekStart.month}-${weekStart.day}.png',
      );
      await imageFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          title: '本周饮食回顾',
          files: [
            XFile(imageFile.path, name: '本周饮食回顾.png', mimeType: 'image/png'),
          ],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('生成分享卡片失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
