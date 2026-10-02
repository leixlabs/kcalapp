import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/diary_providers.dart';
import '../../application/weekly_summary.dart';
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
  bool _isSharing = false;
  String? _editedFocus;

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(weeklyMealsProvider(widget.selectedDate));
    final theme = Theme.of(context);
    final weekStart = weekStartFor(widget.selectedDate);
    final isCurrentWeek = weekStartFor(DateTime.now()) == weekStart;
    final periodEnd = isCurrentWeek
        ? DateTime.now()
        : weekStart.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(title: Text(isCurrentWeek ? '本周回顾' : '周回顾')),
      body: mealsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(
          message: '周总结加载失败：$error',
          onRetry: () =>
              ref.invalidate(weeklyMealsProvider(widget.selectedDate)),
        ),
        data: (meals) {
          final summary = WeeklySummary(weekStart: weekStart, meals: meals);
          final nextWeekFocus = _editedFocus ?? summary.nextWeekFocus;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: WeeklySummaryShareCard(
                  summary: summary,
                  periodEnd: periodEnd,
                  nextWeekFocus: nextWeekFocus,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                meals.isEmpty
                    ? '这一周还没有饮食记录。记录几餐后，就能生成带有真实餐食照片的回顾卡片。'
                    : '图片只使用本周已保存的餐食照片。热量和食物类别均根据本地饮食记录整理，营养数据为估算。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  height: 1.4,
                ),
              ),
              if (meals.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '下周重点',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _editFocus(summary.nextWeekFocus),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('调整'),
                            ),
                          ],
                        ),
                        Text(nextWeekFocus),
                        if (summary.focusCategory case final category?) ...[
                          const SizedBox(height: 10),
                          Text(
                            '参考：${category.label} ${(summary.foodCategoryGrams[category] ?? 0).round()} / ${category.weeklyReferenceGrams.round()} g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '根据本周已记录饮食整理；记录不代表完整饮食，也不构成营养建议。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed: _isSharing || mealsAsync.valueOrNull?.isEmpty != false
                  ? null
                  : () => _generateAndShare(buttonContext),
              icon: _isSharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              label: Text(_isSharing ? '正在生成…' : '生成分享卡片'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editFocus(String suggestedFocus) async {
    final controller = TextEditingController(
      text: _editedFocus ?? suggestedFocus,
    );
    final editedFocus = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('调整下周重点'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          maxLength: 60,
          decoration: const InputDecoration(labelText: '下周想尝试什么？'),
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
    if (!mounted || editedFocus == null || editedFocus.trim().isEmpty) return;
    setState(() => _editedFocus = editedFocus.trim());
  }

  Future<void> _generateAndShare(BuildContext buttonContext) async {
    final shareBox = buttonContext.findRenderObject() as RenderBox?;
    final shareOrigin = shareBox != null && shareBox.hasSize
        ? shareBox.localToGlobal(Offset.zero) & shareBox.size
        : null;
    setState(() => _isSharing = true);
    try {
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
          text: '本周饮食记录整理，营养数据为估算。',
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
