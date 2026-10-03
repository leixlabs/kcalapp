import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 给「点了也没反应」的静态内容补一点反馈：点击回弹缩放 + 震动，
/// 并按需飘出一个 emoji 小彩蛋。
///
/// 纯装饰，不改变子组件布局（空闲时缩放为 1），也不会污染无障碍语义。
class TapDelight extends StatefulWidget {
  const TapDelight({
    super.key,
    required this.child,
    this.emojis = sparkleEmojis,
    this.haptics = true,
    this.onTap,
  });

  final Widget child;

  /// 点击时随机飘出的 emoji；传空列表则只做缩放 + 震动。
  final List<String> emojis;

  /// 是否触发震动反馈（桌面端为无操作）。
  final bool haptics;

  /// 点击时的额外回调（可选）。
  final VoidCallback? onTap;

  /// 通用「小惊喜」表情。
  static const sparkleEmojis = ['✨', '🌟', '💫', '🎉', '🍀', '🥳'];

  /// 食物类表情，适合热量 / 营养素数字。
  static const foodEmojis = ['🍎', '🥑', '🍇', '🥦', '🍙', '🥛', '🍳', '🥕'];

  @override
  State<TapDelight> createState() => _TapDelightState();
}

class _TapDelightState extends State<TapDelight> with TickerProviderStateMixin {
  final math.Random _random = math.Random();

  // 点击回弹：压一下再弹起，最后回正。
  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.93,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.93,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 34,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.04,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 36,
    ),
  ]).animate(_popController);

  // 彩蛋：emoji 放大弹出后淡出。
  late final AnimationController _eggController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 880),
  );
  late final Animation<double> _eggScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.2,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  ]).animate(_eggController);
  late final Animation<double> _eggOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 53),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 35,
    ),
  ]).animate(_eggController);

  bool get _hasEgg => widget.emojis.isNotEmpty;
  String _eggEmoji = '';
  bool _showEgg = false;

  @override
  void dispose() {
    _popController.dispose();
    _eggController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _popController.forward(from: 0);
    if (widget.haptics) {
      if (_hasEgg) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (_hasEgg) {
      setState(() {
        _showEgg = true;
        _eggEmoji = widget.emojis[_random.nextInt(widget.emojis.length)];
      });
      _eggController.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _popScale,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          children: [
            widget.child,
            if (_showEgg)
              Positioned.fill(
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _eggOpacity,
                    child: ScaleTransition(
                      scale: _eggScale,
                      child: Center(
                        child: Text(
                          _eggEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
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
}
