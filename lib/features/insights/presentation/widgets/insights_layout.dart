import 'package:flutter/material.dart';

/// Layout helpers derived from [Size]. Use a single [MediaQuery.sizeOf(context)]
/// in the parent and pass [size] down so cards avoid repeated MediaQuery calls.
class InsightsLayout {
  InsightsLayout(this.size);

  final Size size;

  double get fontScale => (size.shortestSide / 360).clamp(1.0, 1.35);

  EdgeInsets get cardPadding {
    final pad = (size.width * 0.045).clamp(12.0, 24.0);
    return EdgeInsets.all(pad);
  }

  double get cardRadius => (size.shortestSide / 22).clamp(12.0, 20.0);

  double get responsiveIconSize => 16 * fontScale;

  double get infoBannerHorizontalPadding =>
      (size.width * 0.03).clamp(12.0, 20.0);

  double get statItemIconSize => (size.width * 0.11).clamp(36.0, 44.0);

  double ringSize(double width) =>
      (width * 0.22).clamp(64.0, 96.0);

  /// Size for the hero investment recovery circular gauge.
  double get gaugeSize => (size.shortestSide * 0.54).clamp(172.0, 238.0);

  double chartHeight(double height) =>
      (height * 0.22).clamp(160.0, 220.0);
}

/// Top-level helpers when you only have [Size] (e.g. in a StatelessWidget).
double fontScaleFromSize(Size size) =>
    (size.shortestSide / 360).clamp(1.0, 1.35);

EdgeInsets cardPaddingFromSize(Size size) {
  final pad = (size.width * 0.045).clamp(12.0, 24.0);
  return EdgeInsets.all(pad);
}

double cardRadiusFromSize(Size size) =>
    (size.shortestSide / 22).clamp(12.0, 20.0);

double responsiveIconSizeFromSize(Size size) =>
    16 * fontScaleFromSize(size);
