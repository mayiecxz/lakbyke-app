import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/account/providers/account_providers.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/features/account/domain/models/user_model.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/account_info_card.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/settings_section.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/settings_tile.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/change_password_dialog.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
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
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getUserData();
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

  // Future<void> _handleChangeEmail() async {
  //   if (_user == null) return;
  //   
  //   final currentEmail = _user!.email;
  //   final newEmailController = TextEditingController();
  //   
  //   // Show dialog to enter new email
  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (context) => _EmailInputDialog(
  //       currentEmail: currentEmail,
  //       newEmailController: newEmailController,
  //     ),
  //   );

  //   if (result == null || result.isEmpty) return;

  //   final newEmail = result.trim();
  //   
  //   // Validate email format
  //   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Please enter a valid email address'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //     return;
  //   }

  //   if (newEmail == currentEmail) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('New email must be different from current email'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //     }
  //     return;
  //   }

  //   // Show OTP verification dialog
  //   if (mounted) {
  //     final otpResult = await showDialog<Map<String, dynamic>>(
  //       context: context,
  //       builder: (context) => OTPVerificationDialog(
  //         email: currentEmail,
  //         purpose: OTPPurpose.changeEmail,
  //         newEmail: newEmail,
  //       ),
  //     );

  //     if (otpResult != null && otpResult['success'] == true && mounted) {
  //       final otpCode = otpResult['otpCode'] as String?;
  //       if (otpCode != null) {
  //         // Update email after OTP verification
  //         final updateResult = await _userService.updateEmailAfterOTP(otpCode);
  //         
  //         if (updateResult['success'] == true) {
  //           // Reload user data
  //           await _loadUserData();
  //           
  //           if (mounted) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(
  //                 content: Text(updateResult['message'] ?? 'Email updated successfully'),
  //                 backgroundColor: Colors.green,
  //               ),
  //             );
  //           }
  //         } else {
  //           if (mounted) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(
  //                 content: Text(updateResult['error'] ?? 'Failed to update email. Please try again.'),
  //                 backgroundColor: Colors.red,
  //               ),
  //             );
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  Future<void> _handleChangePassword() async {
    if (!ref.read(authServiceProvider).canChangePassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You signed in with Google. Password change is only for email accounts.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );

    if (result == null) return;

    final currentPassword = result['current'];
    final newPassword = result['new'];
    if (currentPassword == null || newPassword == null) return;

    final error = await ref.read(authServiceProvider).changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-screen dark background (for the sides)
            Container(color: Colors.black),
            // 2. Main content area (white)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: _isLoading
                      ? const AppLoadingOverlay(message: 'Loading account...')
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
                              AccountInfoCard(
                                displayName: _user?.displayName ?? 'Loading...',
                                email: _user?.email ?? 'Loading...',
                                serviceTag: _user?.serviceTag ?? 'Loading...',
                                role: _user?.displayRole ?? 'Loading...',
                              ),

                              const SizedBox(height: AppDimensions.paddingLarge),

                              // Security — single Change password entry
                              if (ref.read(authServiceProvider).canChangePassword)
                                SettingsSection(
                                  title: 'Security',
                                  children: [
                                    SettingsTile(
                                      icon: Icons.lock_outline,
                                      title: 'Change password',
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
            const HeaderWithBack(title: 'Account Settings'),
          ],
        ),
      ),
    );
  }
}
