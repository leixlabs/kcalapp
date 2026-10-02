import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../application/weekly_summary.dart';
import '../../../domain/meal.dart';

class WeeklySummaryShareCard extends StatelessWidget {
  final WeeklySummary summary;
  final DateTime periodEnd;
  final String happened;
  final String improvement;

  const WeeklySummaryShareCard({
    super.key,
    required this.summary,
    required this.periodEnd,
    required this.happened,
    required this.improvement,
  });

  static const _ink = Color(0xFF23352A);
  static const _mutedInk = Color(0xFF718078);
  static const _paper = Color(0xFFF7F8F5);
  static const _softGreen = Color(0xFFEAF4EC);
  static const _green = Color(0xFF4CAF73);

  @override
  Widget build(BuildContext context) {
    final averageKcal = summary.averageKcalOnEstimatedDays;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _PeriodHeader(weekStart: summary.weekStart, periodEnd: periodEnd),
              Expanded(
                flex: 9,
                child: _PhotoCollage(meals: summary.photoMeals),
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatPill(
                            label: '有记录',
                            value: '${summary.recordedDays} 天',
                            isPrimary: true,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatPill(
                              label: '已估算日均',
                              value: averageKcal == null
                                  ? '—'
                                  : '${averageKcal.round()} kcal',
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _NarrativeSection(
                        label: '本周锐评',
                        text: happened,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _NarrativeSection(
                        label: '饮食建议',
                        text: improvement,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  final DateTime weekStart;
  final DateTime periodEnd;

  const _PeriodHeader({required this.weekStart, required this.periodEnd});

  @override
  Widget build(BuildContext context) {
    final start = '${weekStart.year}年${weekStart.month}月${weekStart.day}日';
    final end = weekStart.year == periodEnd.year
        ? '${periodEnd.month}月${periodEnd.day}日'
        : '${periodEnd.year}年${periodEnd.month}月${periodEnd.day}日';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          const Icon(
            Icons.event_outlined,
            size: 15,
            color: WeeklySummaryShareCard._green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$start – $end',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WeeklySummaryShareCard._ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrativeSection extends StatelessWidget {
  final String label;
  final String text;
  final int maxLines;

  const _NarrativeSection({
    required this.label,
    required this.text,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WeeklySummaryShareCard._green,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: WeeklySummaryShareCard._ink,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _StatPill({
    required this.label,
    required this.value,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: WeeklySummaryShareCard._softGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WeeklySummaryShareCard._mutedInk,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPrimary
                  ? WeeklySummaryShareCard._green
                  : WeeklySummaryShareCard._ink,
              fontSize: isPrimary ? 18 : 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部图片区：展示本周全部带照片的记录；没有照片时用 3 个占位块。
class _PhotoCollage extends StatelessWidget {
  final List<Meal> meals;

  const _PhotoCollage({required this.meals});

  @override
  Widget build(BuildContext context) {
    final tiles = meals.isEmpty
        ? List<Widget>.generate(3, (_) => const _PhotoPlaceholder())
        : meals.map<Widget>((meal) => _MealPhoto(meal: meal)).toList();
    return _layout(tiles);
  }

  Widget _layout(List<Widget> tiles) {
    switch (tiles.length) {
      case 1:
        return tiles.first;
      case 2:
        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 3),
            Expanded(child: tiles[1]),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(flex: 2, child: tiles[0]),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: tiles[1]),
                  const SizedBox(height: 3),
                  Expanded(child: tiles[2]),
                ],
              ),
            ),
          ],
        );
      default:
        final columns = math.sqrt(tiles.length).ceil().clamp(2, 3);
        return _grid(tiles, columns);
    }
  }

  Widget _grid(List<Widget> tiles, int columns) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += columns) {
      final cells = <Widget>[];
      for (var offset = 0; offset < columns; offset++) {
        if (offset > 0) cells.add(const SizedBox(width: 3));
        final index = start + offset;
        cells.add(
          Expanded(
            child: index < tiles.length
                ? tiles[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 3));
      rows.add(Expanded(child: Row(children: cells)));
    }
    return Column(children: rows);
  }
}

class _MealPhoto extends StatelessWidget {
  final Meal meal;

  const _MealPhoto({required this.meal});

  @override
  Widget build(BuildContext context) {
    final path = meal.photoPath;
    if (path == null || path.isEmpty) return const _PhotoPlaceholder();
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: WeeklySummaryShareCard._softGreen,
      child: Center(
        child: Icon(
          Icons.restaurant_outlined,
          color: WeeklySummaryShareCard._mutedInk,
        ),
      ),
    );
  }
}
