import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Bottom sheet that shows how investment recovery is computed.
class InvestmentRecoveryBreakdownDialog extends StatelessWidget {
  const InvestmentRecoveryBreakdownDialog({super.key, required this.model});

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvestmentRecoveryBreakdownDialog(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'How investment recovery is computed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.homePrimary,
                  ),
            ),
            const SizedBox(height: 20),
            _row(
              context,
              'ROI %',
              '(Total earnings ÷ Initial investment ₱3,792) × 100',
              '${model.roiProgressFormatted}%',
            ),
            const SizedBox(height: 12),
            _row(
              context,
              'Remaining to breakeven',
              '₱3,792 − Total earnings',
              formatCompactCurrency(model.remainingToBreakeven),
            ),
            const SizedBox(height: 12),
            _row(
              context,
              'Breakeven date',
              'Today + (Remaining ÷ Daily average earnings) days',
              model.breakevenDateFormatted,
            ),
            const SizedBox(height: 12),
            _row(
              context,
              'Daily average',
              'Total earnings ÷ Days with activity',
              formatCompactCurrency(model.dailyAverageEarnings),
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

  Widget _row(BuildContext context, String label, String formula, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formula,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.homePrimary,
          ),
        ),
      ],
    );
  }
}
