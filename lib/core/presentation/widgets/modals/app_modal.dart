import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';

/// Standard modal shell for the app: gradient header (optional icon, title, subtitle),
/// body, and action row (optional Cancel + optional Confirm).
/// Matches the Change password dialog design.
class AppModal extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  const AppModal({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.isDestructive = false,
  });

  static const double _radius = 20;
  static const double _elevation = 8;
  static const EdgeInsets _headerPadding =
      EdgeInsets.symmetric(vertical: 24, horizontal: 20);
  static const EdgeInsets _bodyPadding = EdgeInsets.fromLTRB(20, 20, 20, 24);
  static const double _buttonPaddingVertical = 14;
  static const double _buttonGap = 12;
  static const double _confirmButtonRadius = 12;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      elevation: _elevation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Padding(
                padding: _bodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    child,
                    const SizedBox(height: 24),
                    _buildActions(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _headerPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final hasCancel = cancelLabel != null && cancelLabel!.isNotEmpty;
    final hasConfirm = confirmLabel != null && confirmLabel!.isNotEmpty;

    if (!hasCancel && !hasConfirm) {
      return const SizedBox.shrink();
    }

    if (!hasCancel && hasConfirm) {
      return ElevatedButton(
        onPressed: () {
          onConfirm?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: _buttonPaddingVertical),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_confirmButtonRadius),
          ),
          elevation: 0,
        ),
        child: Text(confirmLabel!),
      );
    }

    if (hasCancel && !hasConfirm) {
      return TextButton(
        onPressed: () {
          onCancel?.call();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: _buttonPaddingVertical),
        ),
        child: Text(cancelLabel!),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              onCancel?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding:
                  const EdgeInsets.symmetric(vertical: _buttonPaddingVertical),
            ),
            child: Text(cancelLabel!),
          ),
        ),
        const SizedBox(width: _buttonGap),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: _buttonPaddingVertical),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_confirmButtonRadius),
              ),
              elevation: 0,
            ),
            child: Text(confirmLabel!),
          ),
        ),
      ],
    );
  }
}
