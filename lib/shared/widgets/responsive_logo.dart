import 'package:flutter/material.dart';

/// A responsive logo widget that scales with screen size.
/// Maintains aspect ratio and fills up to maxWidth constraint.
class ResponsiveLogo extends StatelessWidget {
  final String assetPath;
  final double maxWidthPercent; // Max width as percentage of screen (0.0 - 1.0)
  final BoxFit fit;
  final double minWidth; // Minimum width to prevent shrinking too small

  const ResponsiveLogo({
    super.key,
    required this.assetPath,
    this.maxWidthPercent = 0.8,
    this.fit = BoxFit.contain,
    this.minWidth = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * maxWidthPercent;
    final finalWidth = maxWidth > minWidth ? maxWidth : minWidth;

    return SizedBox(
      width: finalWidth,
      child: AspectRatio(
        aspectRatio: 4 / 3, // Adjust based on your logo's aspect ratio
        child: Image.asset(
          assetPath,
          fit: fit,
        ),
      ),
    );
  }
}
