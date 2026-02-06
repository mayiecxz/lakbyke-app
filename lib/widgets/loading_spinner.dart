import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';

/// Standardized loading spinner for the application.
/// Use for initial load, pull-to-refresh, and inline loading states.
class AppLoadingSpinner extends StatelessWidget {
  /// Size of the spinner. [AppSpinnerSize.medium] is the default for full-screen.
  final AppSpinnerSize size;

  /// Optional color. Defaults to [AppColors.homePrimary].
  final Color? color;

  /// Optional stroke width. Defaults by size.
  final double? strokeWidth;

  const AppLoadingSpinner({
    super.key,
    this.size = AppSpinnerSize.medium,
    this.color,
    this.strokeWidth,
  });

  double get _dimension {
    switch (size) {
      case AppSpinnerSize.small:
        return 20.0;
      case AppSpinnerSize.medium:
        return 36.0;
      case AppSpinnerSize.large:
        return 48.0;
    }
  }

  double get _strokeWidth => strokeWidth ?? (size == AppSpinnerSize.small ? 2.0 : 3.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.homePrimary),
      ),
    );
  }
}

/// Sizes for [AppLoadingSpinner].
enum AppSpinnerSize { small, medium, large }

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
