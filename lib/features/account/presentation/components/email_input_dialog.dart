import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';

/// Dialog to enter a new email (used for change-email flow).
class EmailInputDialog extends StatefulWidget {
  final String currentEmail;
  final TextEditingController newEmailController;

  const EmailInputDialog({
    super.key,
    required this.currentEmail,
    required this.newEmailController,
  });

  @override
  State<EmailInputDialog> createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends State<EmailInputDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Current Email: ${widget.currentEmail}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: widget.newEmailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
                hintText: 'Enter your new email address',
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                ElevatedButton(
                  onPressed: () {
                    if (widget.newEmailController.text.isNotEmpty) {
                      Navigator.of(context).pop(widget.newEmailController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
