import 'package:flutter/material.dart';

/// A responsive icon widget that scales with screen size.
/// Automatically adjusts icon size based on screen width and height.
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double maxSizePercent; // Max size as percentage of screen height (0.0 - 1.0)
  final Color color;
  final double minSize; // Minimum icon size

  const ResponsiveIcon({
    super.key,
    required this.icon,
    this.maxSizePercent = 0.15,
    this.color = Colors.black,
    this.minSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxSize = screenHeight * maxSizePercent;
    final finalSize = maxSize > minSize ? maxSize : minSize;

    return Icon(
      icon,
      size: finalSize,
      color: color,
    );
  }
}
