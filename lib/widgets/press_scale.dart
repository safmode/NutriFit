import 'package:flutter/material.dart';

class PressScale extends StatefulWidget {
  final Widget child;

  /// Optional tap to allow PressScale for “display-only” widgets too.
  final VoidCallback? onTap;

  /// Optional: useful for menus / delete / quick actions
  final VoidCallback? onLongPress;

  /// Customize a bit if needed
  final double pressedScale;
  final Duration duration;
  final Curve curve;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOut,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _setDown(bool v) {
    if (!mounted) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) => _setDown(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        duration: widget.duration,
        curve: widget.curve,
        scale: _down ? widget.pressedScale : 1.0,
        child: widget.child,
      ),
    );
  }
}
