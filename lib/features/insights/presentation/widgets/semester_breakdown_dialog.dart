import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Dialog that shows how projected semester earnings is computed.
class SemesterBreakdownDialog extends StatelessWidget {
  const SemesterBreakdownDialog({super.key, required this.model});

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showDialog<void>(
      context: context,
      builder: (context) => SemesterBreakdownDialog(model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'How projected semester earnings is computed',
        style: TextStyle(color: AppColors.homePrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              'Projected earnings',
              'Daily average × Remaining school days',
              '${formatCompactCurrency(model.dailyAverageEarnings)} × ${model.remainingSchoolDays} = ${formatCompactCurrency(model.projectedSemesterEarnings)}',
            ),
            const SizedBox(height: 12),
            _row(
              'Daily average',
              'From your total earnings and days with activity',
              formatCompactCurrency(model.dailyAverageEarnings),
            ),
            const SizedBox(height: 12),
            _row(
              'Remaining school days',
              'Weekdays (Mon–Fri) from today until semester end',
              '${model.remainingSchoolDays} (end: ${DateFormat('MMM d, yyyy').format(model.semesterEndDate)})',
            ),
            if (model.bonusEarningsFor15MinMore > 0) ...[
              const SizedBox(height: 12),
              _row(
                '+15 min bonus',
                'Extra if you ride 15 mins more per day',
                formatCompactCurrency(model.bonusEarningsFor15MinMore),
              ),
            ],
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
