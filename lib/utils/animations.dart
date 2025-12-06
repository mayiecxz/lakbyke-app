import 'package:flutter/material.dart';

/// Centralized animation constants for consistent motion across the app.
abstract class AppAnimations {
  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration modalAnimationDuration = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlowExt = Duration(milliseconds: 800);

  // Curves
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve modalAnimationCurve = Curves.easeOutCubic;
  static const Curve curveBouncy = Curves.elasticOut;

  // Private constructor to prevent instantiation
  AppAnimations._();
}
