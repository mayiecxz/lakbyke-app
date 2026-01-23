import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/services/user_service.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/widgets/validation_dialog.dart';
import 'package:lakbyke_mobile/screens/account/otp_verification_dialog.dart';
import 'package:lakbyke_mobile/models/user/user_model.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getUserData();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleChangeEmail() async {
    if (_user == null) return;
    
    final currentEmail = _user!.email;
    final newEmailController = TextEditingController();
    
    // Show dialog to enter new email
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EmailInputDialog(
        currentEmail: currentEmail,
        newEmailController: newEmailController,
      ),
    );

    if (result == null || result.isEmpty) return;

    final newEmail = result.trim();
    
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (newEmail == currentEmail) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New email must be different from current email'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show OTP verification dialog
    if (mounted) {
      final otpResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => OTPVerificationDialog(
          email: currentEmail,
          purpose: OTPPurpose.changeEmail,
          newEmail: newEmail,
        ),
      );

      if (otpResult != null && otpResult['success'] == true && mounted) {
        final otpCode = otpResult['otpCode'] as String?;
        if (otpCode != null) {
          // Update email after OTP verification
          final updateResult = await _userService.updateEmailAfterOTP(otpCode);
          
          if (updateResult['success'] == true) {
            // Reload user data
            await _loadUserData();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(updateResult['message'] ?? 'Email updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(updateResult['error'] ?? 'Failed to update email. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (_user == null) return;
    
    final currentEmail = _user!.email;
    
    // Show confirmation dialog
    final confirmed = await ValidationDialog.show(
      context,
      title: 'Change Password',
      content: const Text(
        'You will receive an OTP code via email to verify your identity before changing your password.',
      ),
      confirmLabel: 'Continue',
      cancelLabel: 'Cancel',
    );

    if (confirmed != true) return;

    // Show OTP verification dialog
    if (mounted) {
      final otpResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => OTPVerificationDialog(
          email: currentEmail,
          purpose: OTPPurpose.changePassword,
        ),
      );

      if (otpResult != null && otpResult['success'] == true && mounted) {
        final otpCode = otpResult['otpCode'] as String?;
        if (otpCode != null) {
          // Show password input dialog
          final passwordController = TextEditingController();
          final confirmPasswordController = TextEditingController();
          
          final passwordResult = await showDialog<bool>(
            context: context,
            builder: (context) => _PasswordInputDialog(
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
            ),
          );

          if (passwordResult == true) {
            final newPassword = passwordController.text;
            
            // Update password after OTP verification
            final updateResult = await _userService.updatePasswordAfterOTP(
              otpCode: otpCode,
              newPassword: newPassword,
            );
            
            if (updateResult['success'] == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updateResult['message'] ?? 'Password updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updateResult['error'] ?? 'Failed to update password. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/images/lakbike_logo4.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingLarge),

                        // Account Information Card
                        _AccountInfoCard(
                          displayName: _user?.displayName ?? 'Loading...',
                          email: _user?.email ?? 'Loading...',
                          serviceTag: _user?.serviceTag ?? 'Loading...',
                          role: _user?.displayRole ?? 'Loading...',
                        ),

                        const SizedBox(height: AppDimensions.paddingLarge),

                        // Settings Options
                        _SettingsSection(
                          title: 'Security',
                          children: [
                            _SettingsTile(
                              icon: Icons.email_outlined,
                              title: 'Change Email',
                              subtitle: 'Update your email address',
                              onTap: _handleChangeEmail,
                            ),
                            _SettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              onTap: _handleChangePassword,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String serviceTag;
  final String role;

  const _AccountInfoCard({
    required this.displayName,
    required this.email,
    required this.serviceTag,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Divider(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          _InfoRow(
            icon: Icons.tag_outlined,
            label: 'Service Tag',
            value: serviceTag,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailInputDialog extends StatefulWidget {
  final String currentEmail;
  final TextEditingController newEmailController;

  const _EmailInputDialog({
    required this.currentEmail,
    required this.newEmailController,
  });

  @override
  State<_EmailInputDialog> createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends State<_EmailInputDialog> {
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

class _PasswordInputDialog extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const _PasswordInputDialog({
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<_PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<_PasswordInputDialog> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              'Set New Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter your new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            TextField(
              controller: widget.confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your new password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                ElevatedButton(
                  onPressed: () {
                    final password = widget.passwordController.text;
                    final confirmPassword = widget.confirmPasswordController.text;
                    
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 6 characters'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
