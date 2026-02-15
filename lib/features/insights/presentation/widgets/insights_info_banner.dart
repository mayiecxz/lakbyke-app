import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/dimensions.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_layout.dart';

/// Reusable info banner for insights cards (e.g. empty states). Uses [layout] for font scale and padding.
class InsightsInfoBanner extends StatelessWidget {
  const InsightsInfoBanner({
    super.key,
    required this.layout,
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  final InsightsLayout layout;
  final IconData icon;
  final String message;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final s = layout.fontScale;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.infoBannerHorizontalPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: (13 * s).clamp(12.0, 15.0),
                  color: textColor,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
