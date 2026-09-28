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
    final progress = (target != null && target! > 0) ? (consumed / target!).clamp(0.0, 1.0) : 0.0;
    final isOver = target != null && consumed > target!;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _RingPainter(
              progress: progress,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              progressColor: isOver ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                consumed.round().toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOver ? theme.colorScheme.error : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                hasGoal && target != null
                    ? '/ ${target!.round()} kcal'
                    : 'kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = progress * 2 * 3.14159265;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
