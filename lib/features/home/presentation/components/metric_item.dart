import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';

/// Single metric display (icon, value, label, optional subtitle e.g. "Today" / "Live").
class MetricItem extends StatelessWidget {
  final IconData icon;
  final String? value;
  final String label;
  final String? subtitle;
  final bool isLive;

  const MetricItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResponsiveIcon(
          icon: icon,
          maxSizePercent: 0.06,
          color: AppColors.homeAccent,
          minSize: 20.0,
        ),
        const SizedBox(height: 5),
        value != null
            ? Text(
                value!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              )
            : const AppLoadingSpinner(size: AppSpinnerSize.small),
        const SizedBox(height: 2),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLive ? Colors.green : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isLive ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
