import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_layout.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_info_banner.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/semester_breakdown_dialog.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/semester_setup_modal.dart';

/// Section A: Projected semester earnings and +15 min bonus insight.
class ForecasterCard extends StatelessWidget {
  const ForecasterCard({
    super.key,
    required this.model,
    required this.layout,
  });

  final InsightsModel model;
  final InsightsLayout layout;

  @override
  Widget build(BuildContext context) {
    final hasData = model.remainingSchoolDays > 0 && model.dailyAverageEarnings >= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => SemesterBreakdownDialog.show(context, model),
        borderRadius: BorderRadius.circular(layout.cardRadius),
        child: Container(
          width: double.infinity,
          padding: layout.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(layout.cardRadius),
            border: Border.all(
              color: AppColors.homePrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: hasData ? _buildContent(context) : _buildEmptyState(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = layout.fontScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PROJECTED SEMESTER EARNINGS',
          style: TextStyle(
            fontSize: (12 * s).clamp(11.0, 14.0),
            fontWeight: FontWeight.w700,
            color: AppColors.homePrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${formatCompactCurrency(model.projectedSemesterEarnings)} potential',
          style: TextStyle(
            fontSize: (24 * s).clamp(20.0, 28.0),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on ${formatCompactCurrency(model.dailyAverageEarnings)} daily avg over ${model.remainingSchoolDays} remaining school days',
          style: TextStyle(
            fontSize: (13 * s).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        if (model.bonusEarningsFor15MinMore > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.homeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.homeAccent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AppColors.homePrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Riding 15 mins more per day could add ${formatCompactCurrency(model.bonusEarningsFor15MinMore)}',
                    style: TextStyle(
                      fontSize: (13 * s).clamp(12.0, 14.0),
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tap to view breakdown',
              style: TextStyle(
                fontSize: (11 * layout.fontScale).clamp(10.0, 12.0),
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
            FilledButton.icon(
              onPressed: () => SemesterSetupModal.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.homePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text('Set date'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = layout.fontScale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROJECTED SEMESTER EARNINGS',
          style: TextStyle(
            fontSize: (12 * s).clamp(11.0, 14.0),
            fontWeight: FontWeight.w700,
            color: AppColors.homePrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        InsightsInfoBanner(
          layout: layout,
          icon: Icons.auto_awesome_rounded,
          message: 'Complete rides to see your projected semester earnings and tips.',
          backgroundColor: AppColors.homeAccent.withValues(alpha: 0.12),
          iconColor: AppColors.homePrimary,
          textColor: AppColors.darkText,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tap to view breakdown',
              style: TextStyle(
                fontSize: (11 * layout.fontScale).clamp(10.0, 12.0),
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
            FilledButton.icon(
              onPressed: () => SemesterSetupModal.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.homePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text('Set date'),
            ),
          ],
        ),
      ],
    );
  }
}
