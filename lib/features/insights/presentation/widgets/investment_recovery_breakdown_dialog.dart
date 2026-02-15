import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/core/utils/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Dialog that shows how investment recovery is computed.
class InvestmentRecoveryBreakdownDialog extends StatelessWidget {
  const InvestmentRecoveryBreakdownDialog({super.key, required this.model});

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showDialog<void>(
      context: context,
      builder: (context) => InvestmentRecoveryBreakdownDialog(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'How investment recovery is computed',
        style: TextStyle(color: AppColors.homePrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              'ROI %',
              '(Total earnings ÷ Initial investment ₱3,792) × 100',
              '${model.roiProgressFormatted}%',
            ),
            const SizedBox(height: 12),
            _row(
              'Remaining to breakeven',
              '₱3,792 − Total earnings',
              formatCompactCurrency(model.remainingToBreakeven),
            ),
            const SizedBox(height: 12),
            _row(
              'Breakeven date',
              'Today + (Remaining ÷ Daily average earnings) days',
              model.breakevenDateFormatted,
            ),
            const SizedBox(height: 12),
            _row(
              'Daily average',
              'Total earnings ÷ Days with activity',
              formatCompactCurrency(model.dailyAverageEarnings),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _row(String label, String formula, String value) {
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
