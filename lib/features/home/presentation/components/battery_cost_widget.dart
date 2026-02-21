import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';

/// Compact card showing current battery value (cost) based on flat rate per 100% charge.
/// Value is rounded down to nearest ₱5 per payout policy.
class BatteryCostWidget extends StatelessWidget {
  final int? batteryPercent;
  final VoidCallback onTap;

  const BatteryCostWidget({
    super.key,
    required this.batteryPercent,
    required this.onTap,
  });

  static const double ratePer100 = 30.0;

  static num _roundedCost(int? batteryPercent) {
    if (batteryPercent == null) return 0.0;
    final cost = (batteryPercent / 100.0) * ratePer100;
    return roundDownToMultipleOf5(cost);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hasData = batteryPercent != null;
    final displayValue = hasData ? _roundedCost(batteryPercent) : null;
    final width = (w * 0.35).clamp(100.0, 160.0);
    final paddingH = (w * 0.02).clamp(6.0, 12.0);
    final paddingV = (w * 0.025).clamp(8.0, 14.0);
    final circleSize = (w * 0.08).clamp(28.0, 40.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          decoration: BoxDecoration(
            color: AppColors.homeAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.homePrimary.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.homePrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (circleSize * 0.52).clamp(14.0, 20.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: (w * 0.015).clamp(4.0, 10.0)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasData ? '${displayValue!.toInt()}' : '—',
                      style: TextStyle(
                        fontSize: hasData ? (w * 0.078).clamp(28.0, 36.0) : 14,
                        fontWeight: FontWeight.bold,
                        color: hasData ? AppColors.darkText : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: (w * 0.008).clamp(2.0, 4.0)),
              Text(
                'Battery value',
                style: TextStyle(
                  fontSize: (w * 0.032).clamp(12.0, 14.0),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
