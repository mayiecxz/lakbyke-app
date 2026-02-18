import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';

/// Horizontal battery icon whose fill level reflects [percentage] (0–100).
/// Fills left to right. Filled portion uses [fillColor]; outline uses [outlineColor].
class BatteryLevelIcon extends StatelessWidget {
  const BatteryLevelIcon({
    super.key,
    required this.percentage,
    this.size = 48.0,
    this.fillColor,
    this.outlineColor,
  });

  final int? percentage;
  final double size;
  final Color? fillColor;
  final Color? outlineColor;

  static const double _widthRatio = 2.2;

  @override
  Widget build(BuildContext context) {
    final fill = fillColor ?? AppColors.homePrimary;
    final outline = outlineColor ?? AppColors.homePrimary.withValues(alpha: 0.35);
    final level = percentage == null ? 0.0 : (percentage!.clamp(0, 100) / 100.0);

    return CustomPaint(
      size: Size(size * _widthRatio, size),
      painter: _BatteryLevelPainter(
        fillColor: fill,
        outlineColor: outline,
        level: level,
        hasData: percentage != null,
      ),
    );
  }
}

class _BatteryLevelPainter extends CustomPainter {
  _BatteryLevelPainter({
    required this.fillColor,
    required this.outlineColor,
    required this.level,
    required this.hasData,
  });

  final Color fillColor;
  final Color outlineColor;
  final double level;
  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = (h * 0.1).clamp(1.5, 3.0);
    final r = (h * 0.2).clamp(2.0, 6.0);
    final capWidth = h * 0.2;
    final capHeight = h * 0.5;
    final bodyLeft = strokeWidth / 2;
    final bodyRight = w - capWidth - strokeWidth;
    final bodyTop = strokeWidth / 2;
    final bodyBottom = h - strokeWidth / 2;
    final inset = strokeWidth;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom),
      Radius.circular(r),
    );

    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    if (hasData && level > 0) {
      final fillableWidth = (bodyRight - bodyLeft) - 2 * inset;
      final fillWidth = (fillableWidth * level).clamp(0.0, fillableWidth);
      final fillLeft = bodyLeft + inset;
      final fillRight = fillLeft + fillWidth;
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          fillLeft,
          bodyTop + inset,
          fillRight,
          bodyBottom - inset,
        ),
        Radius.circular((r - inset / 2).clamp(0.0, double.infinity)),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }

    canvas.drawRRect(bodyRect, outlinePaint);

    final capRect = Rect.fromLTWH(
      bodyRight + strokeWidth / 2,
      (h - capHeight) / 2,
      capWidth,
      capHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, Radius.circular(strokeWidth)),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryLevelPainter old) {
    return old.level != level || old.fillColor != fillColor || old.outlineColor != outlineColor || old.hasData != hasData;
  }
}
