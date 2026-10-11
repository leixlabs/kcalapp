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
import '../../../../l10n/l10n.dart';
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
      ref
          .read(weeklyReviewControllerProvider)
          .ensure(widget.selectedDate, context.l10n);
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

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCurrentWeek ? l10n.weeklySummaryTitleCurrent : l10n.weeklySummaryTitle,
        ),
        actions: [
          if (hasMeals && hasStoredReview)
            IconButton(
              tooltip: l10n.weeklySummaryAdjustAdvice,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editImprovement,
            ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: l10n.weeklySummaryLoadError('$error'),
          onRetry: () =>
              ref.invalidate(weeklyMealsProvider(widget.selectedDate)),
        ),
        data: (meals) {
          final summary = WeeklySummary(weekStart: weekStart, meals: meals);
          final fallback = WeeklyNarrative(
            happened: summary.happenedSummary(l10n),
            improvement: summary.nextWeekFocus(l10n),
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
              label: Text(
                _isSharing
                    ? l10n.weeklySummaryGenerating
                    : l10n.weeklySummaryGenerateImage,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editImprovement() async {
    final l10n = context.l10n;
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
        : summary.nextWeekFocus(l10n);

    final controller = TextEditingController(text: current);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weeklySummaryAdjustAdvice),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: l10n.weeklySummaryNextWeekQuestion,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.actionApply),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || edited == null || edited.trim().isEmpty) return;
    await ref
        .read(weeklyReviewControllerProvider)
        .editImprovement(widget.selectedDate, edited.trim(), l10n);
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
    final l10n = context.l10n;
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
        throw StateError(l10n.weeklySummaryNoCard);
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw StateError(l10n.weeklySummaryNoImage);

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
          title: l10n.weeklySummaryShareTitle,
          files: [
            XFile(
              imageFile.path,
              name: l10n.weeklySummaryFileName,
              mimeType: 'image/png',
            ),
          ],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.weeklySummaryShareFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
