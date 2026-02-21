import 'package:flutter/material.dart';

/// Centralized screen transition. Use a stable [key] per route for correct animation.
class AnimatedScreenSwitcher extends StatelessWidget {
  const AnimatedScreenSwitcher({
    super.key,
    required this.child,
    this.slideDirection = 0.0,
    this.duration = const Duration(milliseconds: 250),
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
  });

  final Widget child;
  final double slideDirection;
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(slideDirection * 0.2, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
