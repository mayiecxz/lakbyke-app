import 'package:intl/intl.dart';

import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';

/// Bottom sheet that shows how projected semester earnings is computed.
class SemesterBreakdownDialog extends StatelessWidget {
  const SemesterBreakdownDialog({super.key, required this.model});

  final InsightsModel model;

  static Future<void> show(BuildContext context, InsightsModel model) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SemesterBreakdownDialog(model: model),
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
              'How projected semester earnings is computed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.homePrimary,
                  ),
            ),
            const SizedBox(height: 20),
            _row(
              context,
              'Projected earnings',
              'Daily average × Remaining school days',
              '${formatCompactCurrency(model.dailyAverageEarnings)} × ${model.remainingSchoolDays} = ${formatCompactCurrency(model.projectedSemesterEarnings)}',
            ),
            const SizedBox(height: 12),
            _row(
              context,
              'Daily average',
              'From your total earnings and days with activity',
              formatCompactCurrency(model.dailyAverageEarnings),
            ),
            const SizedBox(height: 12),
            _row(
              context,
              'Remaining school days',
              'Weekdays (Mon–Fri) from today until semester end',
              '${model.remainingSchoolDays} (end: ${DateFormat('MMM d, yyyy').format(model.semesterEndDate)})',
            ),
            if (model.bonusEarningsFor15MinMore > 0) ...[
              const SizedBox(height: 12),
              _row(
                context,
                '+15 min bonus',
                'Extra if you ride 15 mins more per day',
                formatCompactCurrency(model.bonusEarningsFor15MinMore),
              ),
            ],
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
