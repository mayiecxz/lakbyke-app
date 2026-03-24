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
        color: AppColors.surface, // Assuming this is an off-white or light grey background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Calculation Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.homePrimary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------
            // GROUP 1: The Final Equation (Hero Card)
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.homePrimary.withValues(alpha: 0.05), // Subtle tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.homePrimary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Projected Semester Earnings',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earned this semester + (Daily avg × Remaining days)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // The actual math formula pops out in its own container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${formatCompactCurrency(model.totalEarnings)} + (${formatCompactCurrency(model.dailyAverageEarnings)} × ${model.remainingSchoolDays}) = ${formatCompactCurrency(model.projectedSemesterEarnings)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.homePrimary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------------------------------------------------------
            // GROUP 2: The Variables (Inputs Card)
            // ---------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, // Clean white card
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildVariableRow(
                    label: 'Earned this semester',
                    description: 'Total earnings since the semester start date',
                    value: formatCompactCurrency(model.totalEarnings),
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildVariableRow(
                    label: 'Daily average',
                    description: 'From your earnings and active days within the semester dates.',
                    value: formatCompactCurrency(model.dailyAverageEarnings),
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildVariableRow(
                    label: 'Remaining school days',
                    description: 'Weekdays (Mon–Fri) from today until semester end',
                    value: '${model.remainingSchoolDays}',
                    subValue: '(end: ${DateFormat('MMM d, yyyy').format(model.semesterEndDate)})',
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // GROUP 3: Potential Extras (Bonus Card)
            // ---------------------------------------------------------
            if (model.bonusEarningsFor15MinMore > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '+15 min bonus',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Extra if you ride 15 mins more per day',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCompactCurrency(model.bonusEarningsFor15MinMore),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// A specialized row builder for the variables card to keep spacing tight and aligned
  Widget _buildVariableRow({
    required String label,
    required String description,
    required String value,
    String? subValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 4),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}