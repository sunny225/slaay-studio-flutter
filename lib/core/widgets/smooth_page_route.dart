import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final AxisDirection direction;

  SmoothPageRoute({
    required this.child,
    this.direction = AxisDirection.right,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset beginOffset;
            switch (direction) {
              case AxisDirection.left:
                beginOffset = const Offset(-0.08, 0.0);
                break;
              case AxisDirection.right:
                beginOffset = const Offset(0.08, 0.0);
                break;
              case AxisDirection.up:
                beginOffset = const Offset(0.0, 0.08);
                break;
              case AxisDirection.down:
                beginOffset = const Offset(0.0, -0.08);
                break;
            }

            final slideAnimation = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            final scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}
