import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/loading/app_loading_spinner.dart';

/// Full-screen loading overlay. Use for initial screen load (e.g. home, history).
class AppLoadingOverlay extends StatelessWidget {
  /// Optional message below the spinner.
  final String? message;

  /// Spinner size.
  final AppSpinnerSize spinnerSize;

  const AppLoadingOverlay({
    super.key,
    this.message,
    this.spinnerSize = AppSpinnerSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoadingSpinner(size: spinnerSize),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
