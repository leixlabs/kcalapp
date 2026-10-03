import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/widgets/meal_photo.dart';
import '../../../application/weekly_summary.dart';
import '../../../domain/food_category.dart';
import '../../../domain/meal.dart';
import '../../home/widgets/food_category_progress_card.dart';

/// 周回顾分享卡片。
///
/// 信息结构自上而下依次为：图片、汇总、每日热力图、食物类别进度、
/// 本周锐评、饮食建议。
class WeeklySummaryShareCard extends StatelessWidget {
  final WeeklySummary summary;
  final DateTime periodEnd;
  final String happened;
  final String improvement;

  /// 本周生效的每日热量目标，用于热力图的达成度配色。
  final double dailyKcalGoal;
  final ValueChanged<Future<void>>? onPhotosReady;

  const WeeklySummaryShareCard({
    super.key,
    required this.summary,
    required this.periodEnd,
    required this.happened,
    required this.improvement,
    required this.dailyKcalGoal,
    this.onPhotosReady,
  });

  static const _ink = Color(0xFF23352A);
  static const _mutedInk = Color(0xFF718078);
  static const _paper = Color(0xFFF7F8F5);
  static const _softGreen = Color(0xFFEAF4EC);
  static const _green = Color(0xFF4CAF73);
  static const _track = Color(0xFFE4E9E3);

  static const _heatEmpty = Color(0xFFEDF0EC);
  static const _heatLow = Color(0xFFD8ECDD);
  static const _heatMid = Color(0xFF9FD4AE);
  static const _heatOver = Color(0xFFE2A15A);

  /// 分享卡片照片缩略图分辨率；导出为图片时会放大，需给足清晰度。
  static const photoThumbSize = 600;

  @override
  Widget build(BuildContext context) {
    final averageKcal = summary.averageKcalOnEstimatedDays;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ShareTitleHeader(),
            _PeriodHeader(weekStart: summary.weekStart, periodEnd: periodEnd),
            _PhotoCollage(
              meals: summary.photoMeals,
              onPhotosReady: onPhotosReady,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AverageKcalCard(averageKcal: averageKcal),
                  const SizedBox(height: 18),
                  const _SectionLabel('每日达成'),
                  const SizedBox(height: 8),
                  _WeeklyHeatmap(
                    weekStart: summary.weekStart,
                    dailyKcal: summary.dailyKcal,
                    goalKcal: dailyKcalGoal,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('食物类别 · 本周'),
                  const SizedBox(height: 10),
                  FoodCategoryProgressCard(
                    weeklyGrams: summary.foodCategoryGrams,
                    showNote: false,
                    labelColor: _ink,
                    mutedColor: _mutedInk,
                    trackColor: _track,
                    categoryColor: _shareCategoryColor,
                  ),
                  const SizedBox(height: 20),
                  _NarrativeSection(label: '本周锐评', text: happened, maxLines: 3),
                  const SizedBox(height: 14),
                  _NarrativeSection(
                    label: '饮食建议',
                    text: improvement,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const _ShareFooter(),
          ],
        ),
      ),
    );
  }

  static Color _shareCategoryColor(FoodCategory category) => switch (category) {
    FoodCategory.grains => const Color(0xFFBF8D42),
    FoodCategory.vegetablesAndFruits => const Color(0xFF4D9A65),
    FoodCategory.meatEggsAndSeafood => const Color(0xFFD77A66),
    FoodCategory.dairyBeansAndNuts => const Color(0xFF6C8FB8),
    FoodCategory.other => _mutedInk,
  };
}

class _ShareTitleHeader extends StatelessWidget {
  const _ShareTitleHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 36, 20, 16),
      child: Text(
        '本周饮食回顾',
        style: TextStyle(
          color: WeeklySummaryShareCard._ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ShareFooter extends StatelessWidget {
  const _ShareFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '生成自 kcalapp',
          style: TextStyle(
            color: WeeklySummaryShareCard._mutedInk,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
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

/// 汇总区：仅保留日均热量。
class _AverageKcalCard extends StatelessWidget {
  final double? averageKcal;

  const _AverageKcalCard({required this.averageKcal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WeeklySummaryShareCard._softGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '已估算日均',
            style: TextStyle(
              color: WeeklySummaryShareCard._mutedInk,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: averageKcal == null ? '—' : '${averageKcal!.round()}',
                  style: const TextStyle(
                    color: WeeklySummaryShareCard._green,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (averageKcal != null)
                  const TextSpan(
                    text: ' kcal',
                    style: TextStyle(
                      color: WeeklySummaryShareCard._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 每日热量热力图：按当天摄入相对目标的达成度着色。
class _WeeklyHeatmap extends StatelessWidget {
  final DateTime weekStart;
  final Map<DateTime, double> dailyKcal;
  final double goalKcal;

  const _WeeklyHeatmap({
    required this.weekStart,
    required this.dailyKcal,
    required this.goalKcal,
  });

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < 7; i++) {
      if (i > 0) cells.add(const SizedBox(width: 6));
      final day = weekStart.add(Duration(days: i));
      final kcal = dailyKcal[DateTime(day.year, day.month, day.day)] ?? 0;
      final level = _levelFor(kcal);
      cells.add(
        Expanded(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: level.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: level.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _weekdayLabels[i],
                style: const TextStyle(
                  color: WeeklySummaryShareCard._mutedInk,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: cells),
        const SizedBox(height: 10),
        const Row(
          children: [
            _HeatLegend(color: WeeklySummaryShareCard._heatEmpty, label: '未记录'),
            SizedBox(width: 12),
            _HeatLegend(color: WeeklySummaryShareCard._heatLow, label: '偏少'),
            SizedBox(width: 12),
            _HeatLegend(color: WeeklySummaryShareCard._heatMid, label: '接近'),
            SizedBox(width: 12),
            _HeatLegend(color: WeeklySummaryShareCard._green, label: '达标'),
            SizedBox(width: 12),
            _HeatLegend(color: WeeklySummaryShareCard._heatOver, label: '超出'),
          ],
        ),
      ],
    );
  }

  ({Color color, Color text}) _levelFor(double kcal) {
    if (kcal <= 0) {
      return (
        color: WeeklySummaryShareCard._heatEmpty,
        text: WeeklySummaryShareCard._mutedInk,
      );
    }
    final ratio = goalKcal <= 0 ? 1.0 : kcal / goalKcal;
    if (ratio < 0.5) {
      return (
        color: WeeklySummaryShareCard._heatLow,
        text: WeeklySummaryShareCard._ink,
      );
    }
    if (ratio < 0.85) {
      return (
        color: WeeklySummaryShareCard._heatMid,
        text: WeeklySummaryShareCard._ink,
      );
    }
    if (ratio <= 1.1) {
      return (color: WeeklySummaryShareCard._green, text: Colors.white);
    }
    return (color: WeeklySummaryShareCard._heatOver, text: Colors.white);
  }
}

class _HeatLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _HeatLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: WeeklySummaryShareCard._mutedInk,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WeeklySummaryShareCard._green,
        fontSize: 11,
        fontWeight: FontWeight.w700,
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
        _SectionLabel(label),
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

/// 顶部图片区：本周带照片的记录，便当盒布局。
///
/// 没有照片时整块收起，不使用占位图；照片超过展示上限时，
/// 在最后一张叠加「+N」提示未展示的数量。
class _PhotoCollage extends StatefulWidget {
  final List<Meal> meals;
  final ValueChanged<Future<void>>? onPhotosReady;

  const _PhotoCollage({required this.meals, this.onPhotosReady});

  @override
  State<_PhotoCollage> createState() => _PhotoCollageState();
}

class _PhotoCollageState extends State<_PhotoCollage> {
  static const _maxTiles = 9;
  static const _gap = 3.0;

  late Future<List<Meal>> _readableMeals;

  @override
  void initState() {
    super.initState();
    _setReadableMealsFuture();
  }

  @override
  void didUpdateWidget(covariant _PhotoCollage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMeals(oldWidget.meals, widget.meals)) {
      _setReadableMealsFuture();
    }
  }

  void _setReadableMealsFuture() {
    _readableMeals = _findReadableMeals(widget.meals);
    widget.onPhotosReady?.call(_readableMeals.then<void>((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Meal>>(
      future: _readableMeals,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AspectRatio(
            aspectRatio: 4 / 3,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final meals = snapshot.data!;
        if (meals.isEmpty) return const SizedBox.shrink();

        final overflow = meals.length - _maxTiles;
        final visible = meals.take(_maxTiles).toList();
        final tiles = <Widget>[
          for (var i = 0; i < visible.length; i++)
            if (overflow > 0 && i == visible.length - 1)
              Stack(
                fit: StackFit.expand,
                children: [
                  _MealPhoto(meal: visible[i]),
                  ColoredBox(
                    color: const Color(0x66000000),
                    child: Center(
                      child: Text(
                        '+$overflow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              _MealPhoto(meal: visible[i]),
        ];

        return AspectRatio(aspectRatio: 4 / 3, child: _layout(tiles));
      },
    );
  }

  Future<List<Meal>> _findReadableMeals(List<Meal> meals) =>
      filterReadablePhotoMeals(meals, (meal) {
        final provider = MealPhotoProvider.maybe(
          assetId: meal.photoAssetId,
          path: meal.photoPath,
          thumbSize: WeeklySummaryShareCard.photoThumbSize,
        );
        return provider?.isReadable() ?? Future.value(false);
      });

  bool _sameMeals(List<Meal> a, List<Meal> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].photoAssetId != b[i].photoAssetId ||
          a[i].photoPath != b[i].photoPath) {
        return false;
      }
    }
    return true;
  }

  Widget _layout(List<Widget> tiles) {
    switch (tiles.length) {
      case 1:
        return tiles.first;
      case 2:
        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: _gap),
            Expanded(child: tiles[1]),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(flex: 2, child: tiles[0]),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: tiles[1]),
                  const SizedBox(height: _gap),
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
        if (offset > 0) cells.add(const SizedBox(width: _gap));
        final index = start + offset;
        cells.add(
          Expanded(
            child: index < tiles.length
                ? tiles[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
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
    // 找不到的图片不再使用占位图：默认占位为空，仅留背景色。
    return MealPhoto(
      assetId: meal.photoAssetId,
      path: meal.photoPath,
      thumbSize: WeeklySummaryShareCard.photoThumbSize,
    );
  }
}
