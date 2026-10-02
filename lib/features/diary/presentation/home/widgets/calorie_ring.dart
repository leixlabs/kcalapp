import 'dart:math' as math;

import 'package:flutter/material.dart';

class CalorieRing extends StatelessWidget {
  final double consumed;
  final double? target;
  final bool hasGoal;

  const CalorieRing({
    super.key,
    required this.consumed,
    this.target,
    this.hasGoal = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (target != null && target! > 0)
        ? (consumed / target!).clamp(0.0, 1.0)
        : 0.0;
    final isOver = target != null && consumed > target!;

    // Keep the main calorie value visually dominant inside the half-ring.
    return SizedBox(
      width: 176,
      height: 112,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(
            size: const Size(160, 100),
            painter: _HalfRingPainter(
              progress: progress,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              progressColor: isOver
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
          // 文字居中显示在半环底部
          Positioned(
            bottom: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '已摄入',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      consumed.round().toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isOver
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kcal',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HalfRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _HalfRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 8);
    final radius = size.width / 2 - 10;

    // 半环从左侧 180° 到右侧 0°（即从 π 到 0，即上半部分）
    const startAngle = math.pi; // 从左侧开始
    const sweepTotal = math.pi; // 扫过 180°（上半圆）

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // 画背景轨道（完整上半弧）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // 画进度弧
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HalfRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
