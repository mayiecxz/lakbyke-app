import 'package:flutter/material.dart';

/// A responsive image widget that scales with screen size.
/// Fills width up to maxWidthPercent and maintains aspect ratio.
class ResponsiveImage extends StatelessWidget {
  final String assetPath;
  final double maxWidthPercent; // Max width as percentage of screen (0.0 - 1.0)
  final double? aspectRatio; // Optional aspect ratio (width/height)
  final BoxFit fit;
  final double minWidth; // Minimum width to prevent shrinking too small

  const ResponsiveImage({
    super.key,
    required this.assetPath,
    this.maxWidthPercent = 0.9,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.minWidth = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * maxWidthPercent;
    final finalWidth = maxWidth > minWidth ? maxWidth : minWidth;

    if (aspectRatio != null) {
      return SizedBox(
        width: finalWidth,
        child: AspectRatio(
          aspectRatio: aspectRatio!,
          child: Image.asset(
            assetPath,
            fit: fit,
          ),
        ),
      );
    }

    // If no aspect ratio specified, let image determine its own size
    return SizedBox(
      width: finalWidth,
      child: Image.asset(
        assetPath,
        fit: fit,
      ),
    );
  }
}
