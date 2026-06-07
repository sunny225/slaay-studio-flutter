import 'package:flutter/material.dart';

class PressScaleEffect extends StatefulWidget {
  final Widget child;
  final double scaleDownTo;
  final Duration duration;
  final VoidCallback? onTap;

  const PressScaleEffect({
    super.key,
    required this.child,
    this.scaleDownTo = 0.94,
    this.duration = const Duration(milliseconds: 120),
    this.onTap,
  });

  @override
  State<PressScaleEffect> createState() => _PressScaleEffectState();
}

class _PressScaleEffectState extends State<PressScaleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    } else {
      return Listener(
        onPointerDown: (_) => _controller.forward(),
        onPointerUp: (_) => _controller.reverse(),
        onPointerCancel: (_) => _controller.reverse(),
        child: result,
      );
    }
  }
}
