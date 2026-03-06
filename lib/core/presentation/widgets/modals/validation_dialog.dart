import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/modals/app_modal.dart';

class ValidationDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  const ValidationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.isDestructive = false,
  });

  static Future<bool?> show(BuildContext context,
      {required String title,
      required Widget content,
      String confirmLabel = 'Confirm',
      String cancelLabel = 'Cancel',
      VoidCallback? onConfirm,
      bool isDestructive = false}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ValidationDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: title,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () {
        Navigator.of(context).pop(true);
        onConfirm?.call();
      },
      child: content,
    );
  }
}
