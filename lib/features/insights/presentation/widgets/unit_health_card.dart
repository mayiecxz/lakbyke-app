import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_layout.dart';

/// Section B: Unit health status, health bar (0–2000 km), maintenance tier copy.
class UnitHealthCard extends StatelessWidget {
  const UnitHealthCard({
    super.key,
    required this.model,
    required this.layout,
  });

  final InsightsModel model;
  final InsightsLayout layout;

  @override
  Widget build(BuildContext context) {
    final s = layout.fontScale;
    final statusColor = _statusColor(model.unitHealthStatus);
    const maxKm = 2000.0;
    final progress = (model.totalDistanceKm / maxKm).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: layout.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UNIT HEALTH',
                style: TextStyle(
                  fontSize: (12 * s).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.homePrimary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '#${model.mntTag}',
                  style: TextStyle(
                    fontSize: (12 * s).clamp(11.0, 13.0),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.textTertiary.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            model.unitHealthLabel,
            style: TextStyle(
              fontSize: (15 * s).clamp(14.0, 17.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${model.totalDistanceKm.toStringAsFixed(0)} km ridden',
            style: TextStyle(
              fontSize: (13 * s).clamp(12.0, 14.0),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model.unitHealthDescription,
            style: TextStyle(
              fontSize: (13 * s).clamp(12.0, 14.0),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'excellent':
        return AppColors.success;
      case 'bolt_check':
        return AppColors.warning;
      case 'motor_inspection':
        return AppColors.error;
      default:
        return AppColors.homePrimary;
    }
  }
}
