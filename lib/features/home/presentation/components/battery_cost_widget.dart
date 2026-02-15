import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';

/// Compact card showing current battery value (cost) based on flat rate per 100% charge.
class BatteryCostWidget extends StatelessWidget {
  final int? batteryPercent;
  final VoidCallback onTap;

  const BatteryCostWidget({
    super.key,
    required this.batteryPercent,
    required this.onTap,
  });

  static const double ratePer100 = 30.0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hasData = batteryPercent != null;
    final cost = hasData ? (batteryPercent! / 100.0) * ratePer100 : 0.0;
    final width = (w * 0.22).clamp(80.0, 110.0);
    final paddingH = (w * 0.025).clamp(8.0, 12.0);
    final paddingV = (w * 0.03).clamp(10.0, 14.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: width, minHeight: 48),
          child: Container(
            width: width,
            padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
            decoration: BoxDecoration(
              color: AppColors.homeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.homePrimary.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: AppColors.homePrimary, size: (w * 0.055).clamp(18.0, 24.0)),
                SizedBox(height: (w * 0.01).clamp(2.0, 6.0)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasData ? '₱${cost.toStringAsFixed(0)}' : '—',
                    style: TextStyle(
                      fontSize: hasData ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      color: hasData ? AppColors.darkText : Colors.grey,
                    ),
                  ),
                ),
                Text(
                  'Value',
                  style: TextStyle(
                    fontSize: (w * 0.028).clamp(10.0, 12.0),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
