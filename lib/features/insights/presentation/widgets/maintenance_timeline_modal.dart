import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Modal showing recommended maintenance timeline by distance.
/// Clarifies that these are recommendations only, not requirements.
class MaintenanceTimelineModal extends StatelessWidget {
  const MaintenanceTimelineModal({
    super.key,
    required this.model,
  });

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaintenanceTimelineModal(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalKm = model.totalDistanceKm;
    final currentStatus = model.unitHealthStatus;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recommended maintenance timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.homePrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'This timeline is a recommendation only—not a requirement from the app developers. You decide when to maintain your unit based on your own use and technician advice.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            _TimelineItem(
              fromKm: 0,
              toKm: 500,
              label: 'Condition: Excellent',
              description: 'No maintenance actions needed.',
              status: 'excellent',
              currentStatus: currentStatus,
              totalKm: totalKm,
            ),
            _TimelineConnector(isActive: totalKm >= 500),
            _TimelineItem(
              fromKm: 500,
              toKm: 2000,
              label: 'Check mounting bolts',
              description: 'Have a technician verify mounting bolts for safety.',
              status: 'bolt_check',
              currentStatus: currentStatus,
              totalKm: totalKm,
            ),
            _TimelineConnector(isActive: totalKm >= 2000),
            _TimelineItem(
              fromKm: 2000,
              toKm: null,
              label: 'Inspect motor brushes',
              description: 'Schedule motor brush inspection to maintain performance.',
              status: 'motor_inspection',
              currentStatus: currentStatus,
              totalKm: totalKm,
            ),
            const SizedBox(height: 16),
            Text(
              'Your unit: ${totalKm.toStringAsFixed(0)} km ridden',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.homePrimary,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.fromKm,
    required this.toKm,
    required this.label,
    required this.description,
    required this.status,
    required this.currentStatus,
    required this.totalKm,
  });

  final int fromKm;
  final int? toKm;
  final String label;
  final String description;
  final String status;
  final String currentStatus;
  final double totalKm;

  Color get _statusColor {
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

  bool get _isCurrent => status == currentStatus;

  @override
  Widget build(BuildContext context) {
    final rangeText = toKm != null ? '$fromKm – $toKm km' : '$fromKm+ km';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCurrent ? _statusColor : _statusColor.withValues(alpha: 0.4),
            border: _isCurrent
                ? Border.all(color: _statusColor, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    rangeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'You are here',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Container(
        width: 2,
        height: 12,
        color: isActive
            ? AppColors.textTertiary
            : AppColors.textTertiary.withValues(alpha: 0.4),
      ),
    );
  }
}
