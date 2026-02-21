import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/home/presentation/components/battery_cost_widget.dart';

/// Modal that explains battery value formula and shows current battery value.
class BatteryCostModal {
  BatteryCostModal._();

  static void show(BuildContext context, int? batteryPercent) {
    final hasData = batteryPercent != null;
    final rawCost = hasData ? (batteryPercent / 100.0) * BatteryCostWidget.ratePer100 : 0.0;
    final cost = hasData ? roundDownToMultipleOf5(rawCost).toDouble() : 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Battery value',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Equivalent price of your charged battery as of this moment, based on a flat rate per full charge.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.homeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.homePrimary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formula',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Battery % × ₱${BatteryCostWidget.ratePer100.toStringAsFixed(0)}.00 per 100% charge, then rounded down to nearest ₱5',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current battery',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? '$batteryPercent%' : 'No battery data',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Current battery value',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF317263)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? '₱${cost.toInt()}' : '—',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF317263)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Payout policy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payouts are issued in multiples of ₱5 only. Amounts shown are rounded down to the nearest ₱5 to reflect this limit.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF317263),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
