import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/modals/app_modal.dart';

/// Dialog: current password, new password, confirm password (no OTP/email verification).
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final current = _currentController.text;
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your current password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a new password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirmation do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(<String, String>{'current': current, 'new': newPass});
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.grey.shade600,
          size: 22,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.lock_reset_rounded,
      title: 'Change password',
      subtitle: 'Enter your current password, then set a new one.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Update password',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentController,
            decoration: _inputDecoration(
              label: 'Current password',
              hint: 'Enter current password',
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            obscureText: _obscureCurrent,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newController,
            decoration: _inputDecoration(
              label: 'New password',
              hint: 'At least 6 characters',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            obscureText: _obscureNew,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            decoration: _inputDecoration(
              label: 'Confirm new password',
              hint: 'Re-enter new password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            obscureText: _obscureConfirm,
          ),
        ],
      ),
    );
  }
}
