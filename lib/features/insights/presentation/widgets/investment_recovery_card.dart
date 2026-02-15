import 'package:flutter/material.dart';

import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/core/utils/formatting.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/insights_layout.dart';
import 'package:lakbyke_mobile/features/insights/presentation/widgets/investment_recovery_breakdown_dialog.dart';

/// Hero card: circular ROI gauge, investment recovered %, breakeven date.
class InvestmentRecoveryCard extends StatelessWidget {
  const InvestmentRecoveryCard({
    super.key,
    required this.model,
    required this.layout,
  });

  final InsightsModel model;
  final InsightsLayout layout;

  @override
  Widget build(BuildContext context) {
    final hasData = model.totalEarnings > 0 || model.dailyAverageEarnings > 0;

    return Container(
      width: double.infinity,
      padding: layout.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.homeAccent.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasData ? _buildContent(context) : _buildEmptyState(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = layout.fontScale;
    final gaugeSize = layout.gaugeSize;
    final progress = (model.roiProgressPercent / 100.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: gaugeSize,
          height: gaugeSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(gaugeSize, gaugeSize),
                painter: _InvestmentGaugePainter(
                  progress: progress,
                  strokeWidth: 12,
                  trackColor: AppColors.homeAccent.withValues(alpha: 0.25),
                  progressColor: AppColors.homeAccent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${model.roiProgressFormatted}%',
                    style: TextStyle(
                      fontSize: (32 * s).clamp(26.0, 40.0),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOnPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.hasRecoveredInvestment
                        ? 'Investment Recovered'
                        : 'Investment Recovery',
                    style: TextStyle(
                      fontSize: (14 * s).clamp(12.0, 16.0),
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatCompactCurrency(model.totalEarnings)} / ${formatCompactCurrency(CBAConstants.cyclistCapex)}',
                    style: TextStyle(
                      fontSize: (15 * s).clamp(13.0, 17.0),
                      color: AppColors.homeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          model.breakevenDateFormatted,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (13 * s).clamp(12.0, 15.0),
            color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => InvestmentRecoveryBreakdownDialog.show(context, model),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.homeAccent,
            side: const BorderSide(color: AppColors.homeAccent),
          ),
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('View breakdown'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = layout.fontScale;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 48,
            color: AppColors.homeAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your first session to start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (14 * s).clamp(13.0, 16.0),
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a 270° arc gauge (bottom-centered) with optional glow on the progress segment.
class _InvestmentGaugePainter extends CustomPainter {
  _InvestmentGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  static const double _sweepDegrees = 270;
  static const double _startAngle = 135;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startRad = _startAngle * 3.14159265359 / 180;
    final sweepRad = _sweepDegrees * 3.14159265359 / 180;

    canvas.drawArc(rect, startRad, sweepRad, false, trackPaint);

    if (progress > 0) {
      final progressSweep = sweepRad * progress;
      canvas.drawArc(rect, startRad, progressSweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InvestmentGaugePainter old) {
    return old.progress != progress ||
        old.strokeWidth != strokeWidth ||
        old.trackColor != trackColor ||
        old.progressColor != progressColor;
  }
}
