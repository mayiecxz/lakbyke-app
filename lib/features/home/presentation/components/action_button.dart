import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';

/// Action button on home screen (Total Generated, Total Redeems, Batteries Exchanged).
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String? value;
  final Color color;
  final double width;
  final bool isCurrency;
  final bool isFullWidth;
  final VoidCallback? onViewHistory;

  const ActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.width,
    this.isCurrency = false,
    this.isFullWidth = false,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewHistory,
        borderRadius: BorderRadius.circular(AppDimensions.homeActionButtonRadius),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppDimensions.homeActionButtonPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF317263),
            borderRadius: BorderRadius.circular(AppDimensions.homeActionButtonRadius),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (!isFullWidth)
                Column(
                  children: [
                    Icon(icon, color: Colors.white, size: 40.0),
                    const SizedBox(height: 8),
                    title != null
                        ? Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white),
                  ],
                ),
              if (isFullWidth)
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 32.0),
                    const SizedBox(width: 12),
                    Expanded(
                      child: title != null
                          ? Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : const Center(child: AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white)),
                    ),
                  ],
                ),
              if (value != null && value!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      value!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onViewHistory,
                      child: Text(
                        'View History',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              else if (!isFullWidth && value == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: AppLoadingSpinner(size: AppSpinnerSize.small, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
