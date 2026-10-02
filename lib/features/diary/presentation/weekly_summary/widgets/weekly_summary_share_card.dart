import 'dart:io';

import 'package:flutter/material.dart';

import '../../../application/weekly_summary.dart';
import '../../../domain/meal.dart';

class WeeklySummaryShareCard extends StatelessWidget {
  final WeeklySummary summary;
  final DateTime periodEnd;
  final String? nextWeekFocus;

  const WeeklySummaryShareCard({
    super.key,
    required this.summary,
    required this.periodEnd,
    this.nextWeekFocus,
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
              Expanded(
                flex: 11,
                child: _PhotoCollage(
                  meals: summary.photoMeals,
                  weekStart: summary.weekStart,
                  periodEnd: periodEnd,
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '一周饮食回顾',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const Spacer(),
                      const Text(
                        '下周试试',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nextWeekFocus ?? summary.nextWeekFocus,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '根据本周已记录饮食整理 · 营养数据为估算',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mutedInk, fontSize: 9),
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

class _PhotoCollage extends StatelessWidget {
  final List<Meal> meals;
  final DateTime weekStart;
  final DateTime periodEnd;

  const _PhotoCollage({
    required this.meals,
    required this.weekStart,
    required this.periodEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.primaryContainer;
    final foreground = theme.colorScheme.onPrimaryContainer;
    final dates =
        '${weekStart.month}/${weekStart.day}—${periodEnd.month}/${periodEnd.day}';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (meals.isEmpty)
          ColoredBox(
            color: background,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_outlined, color: foreground, size: 44),
                  const SizedBox(height: 8),
                  Text(
                    '这一周的饮食记录',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildPhotos(context),
        Positioned(
          top: 12,
          left: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                dates,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos(BuildContext context) {
    if (meals.length == 1) return _photo(meals.first);
    if (meals.length == 2) {
      return Row(
        children: [
          Expanded(child: _photo(meals[0])),
          const SizedBox(width: 3),
          Expanded(child: _photo(meals[1])),
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 2, child: _photo(meals[0])),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _photo(meals[1])),
              const SizedBox(height: 3),
              Expanded(child: _photo(meals[2])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photo(Meal meal) {
    final path = meal.photoPath;
    if (path == null || path.isEmpty) {
      return const ColoredBox(color: WeeklySummaryShareCard._softGreen);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: WeeklySummaryShareCard._softGreen,
        child: Center(
          child: Icon(
            Icons.restaurant_outlined,
            color: WeeklySummaryShareCard._mutedInk,
          ),
        ),
      ),
    );
  }
}
