import 'package:flutter/material.dart';

/// A responsive text widget that scales with screen size.
/// Font size scales based on screen width for better readability.
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseSize; // Base font size for reference screen width (360dp)
  final FontWeight fontWeight;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.color = Colors.black,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    // Scale factor based on screen width (reference width is 360dp)
    final scaleFactor = MediaQuery.of(context).size.width / 360.0;
    final responsiveSize = baseSize * scaleFactor;

    // Cap the scaling to prevent text from becoming too large
    final finalSize = responsiveSize > baseSize * 2.0 ? baseSize * 2.0 : responsiveSize;

    return Text(
      text,
      style: TextStyle(
        fontSize: finalSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
