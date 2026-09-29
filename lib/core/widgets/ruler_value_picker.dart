import 'dart:math' as math;

import 'package:flutter/material.dart';

class RulerValuePicker extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  const RulerValuePicker({
    super.key,
    required this.value,
    this.min = 0,
    required this.max,
    this.step = 0.1,
    required this.unit,
    required this.color,
    required this.onChanged,
  }) : assert(step > 0);

  @override
  State<RulerValuePicker> createState() => _RulerValuePickerState();
}

class _RulerValuePickerState extends State<RulerValuePicker> {
  static const double _tickExtent = 12;
  late final ScrollController _controller;
  late int _tickCount;
  late int _selectedTick;

  @override
  void initState() {
    super.initState();
    _tickCount = ((widget.max - widget.min) / widget.step).round();
    _selectedTick = _valueToTick(widget.value);
    _controller = ScrollController(
      initialScrollOffset: _selectedTick * _tickExtent,
    )..addListener(_updateSelectedTick);
  }

  @override
  void didUpdateWidget(covariant RulerValuePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.step != widget.step) {
      _tickCount = ((widget.max - widget.min) / widget.step).round();
      _selectedTick = _valueToTick(widget.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpTo(_selectedTick * _tickExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_updateSelectedTick)
      ..dispose();
    super.dispose();
  }

  int _valueToTick(double value) =>
      ((value.clamp(widget.min, widget.max) - widget.min) / widget.step)
          .round()
          .clamp(0, _tickCount);

  void _updateSelectedTick() {
    final nextTick = (_controller.offset / _tickExtent).round().clamp(
      0,
      _tickCount,
    );
    if (nextTick == _selectedTick) return;
    setState(() => _selectedTick = nextTick);
    widget.onChanged(widget.min + nextTick * widget.step);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.min + _selectedTick * widget.step;
    final majorInterval = (1 / widget.step).round().clamp(1, _tickCount + 1);
    final mediumInterval = (majorInterval / 2).round().clamp(1, majorInterval);
    final decimalPlaces = widget.step >= 1
        ? 0
        : ((-math.log(widget.step) / math.ln10).ceil()).clamp(0, 4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.toStringAsFixed(decimalPlaces),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              TextSpan(
                text: ' ${widget.unit}',
                style: TextStyle(
                  fontSize: 22,
                  color: widget.color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 104,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final edgeInset = (constraints.maxWidth - _tickExtent) / 2;
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const _PreciseRulerPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: edgeInset),
                    itemExtent: _tickExtent,
                    itemCount: _tickCount + 1,
                    itemBuilder: (context, index) {
                      final isMajor = index % majorInterval == 0;
                      final isMedium = !isMajor && index % mediumInterval == 0;
                      final tickHeight = isMajor
                          ? 34.0
                          : isMedium
                          ? 26.0
                          : 18.0;
                      final tickValue = widget.min + index * widget.step;

                      return SizedBox(
                        width: _tickExtent,
                        child: Column(
                          children: [
                            Container(
                              width: isMajor ? 2 : 1.5,
                              height: tickHeight,
                              color: Colors.grey.withValues(
                                alpha: isMajor ? 0.34 : 0.24,
                              ),
                            ),
                            if (isMajor)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  tickValue.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  IgnorePointer(
                    child: Column(
                      children: [
                        ClipPath(
                          clipper: _RulerPointerClipper(),
                          child: Container(
                            width: 22,
                            height: 14,
                            color: widget.color,
                          ),
                        ),
                        Container(width: 2, height: 78, color: widget.color),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RulerPointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width / 2, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PreciseRulerPhysics extends ClampingScrollPhysics {
  const _PreciseRulerPhysics({super.parent});

  @override
  _PreciseRulerPhysics applyTo(ScrollPhysics? ancestor) =>
      _PreciseRulerPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) => null;
}
