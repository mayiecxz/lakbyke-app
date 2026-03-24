import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/account/providers/account_providers.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart';
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart';
import 'package:lakbyke_mobile/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/features/account/domain/models/user_model.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/account_info_card.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/settings_section.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/settings_tile.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/change_password_dialog.dart';
import 'package:lakbyke_mobile/features/account/presentation/components/about_lakbyke_bottom_sheet.dart'; 

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

  void _showAboutDialog(BuildContext context) {
    AboutLakBykeBottomSheet.show(context);
  }

  void _openChatbot(BuildContext context) {
    ref.read(shellNavigatorKeyProvider)?.currentState?.push(
      buildChatbotPageRoute(
        const ChatbotScreen(),
        settings: const RouteSettings(name: ShellRoutes.chatbot),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final navigator = Navigator.of(context);
    ValidationDialog.show(
      context,
      title: 'Confirm Logout',
      content: const Text('Are you sure you want to logout?'),
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        try {
          await ref.read(authServiceProvider).signOut();
          if (navigator.mounted) {
            ref.read(appRouterControllerProvider.notifier).goToOnboarding();
          }
        } catch (e) {
          if (navigator.mounted) {
            ScaffoldMessenger.of(navigator.context).showSnackBar(
              SnackBar(
                content: Text('Error during logout: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

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

                              // Security — Change password (if email account)
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

                              if (ref.read(authServiceProvider).canChangePassword)
                                const SizedBox(height: AppDimensions.paddingLarge),

                              // About, Chatbot, Logout — typical app actions
                              SettingsSection(
                                title: 'Support & account',
                                children: [
                                  SettingsTile(
                                    icon: Icons.info_outline,
                                    title: 'About',
                                    subtitle: 'App info and version',
                                    onTap: () => _showAboutDialog(context),
                                  ),
                                  SettingsTile(
                                    icon: Icons.chat_outlined,
                                    title: 'Chatbot',
                                    subtitle: 'Get help and answers',
                                    onTap: () => _openChatbot(context),
                                  ),
                                  SettingsTile(
                                    icon: Icons.logout,
                                    title: 'Logout',
                                    subtitle: 'Sign out of your account',
                                    onTap: () => _handleLogout(context),
                                    isDestructive: true,
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
