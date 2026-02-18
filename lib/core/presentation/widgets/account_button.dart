import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart';
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/validation_dialog.dart';
import 'package:lakbyke_mobile/features/account/presentation/screens/account_settings_screen.dart';
import 'package:lakbyke_mobile/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/account_menu_item.dart';

/// Account icon button in the header that opens a popup menu (settings, help, logout).
class AccountButton extends ConsumerStatefulWidget {
  const AccountButton({super.key});

  @override
  ConsumerState<AccountButton> createState() => _AccountButtonState();
}

class _AccountButtonState extends ConsumerState<AccountButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAccountMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + buttonSize.width - 200,
        buttonPosition.dy + buttonSize.height + 8,
        overlay.size.width - buttonPosition.dx - buttonSize.width,
        overlay.size.height - buttonPosition.dy - buttonSize.height,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'change_password',
          child: AccountMenuItem(
            icon: Icons.lock_outline,
            title: 'Change password',
            isDestructive: false,
            onTap: () {
              Navigator.pop(context);
              ref.read(shellNavigatorKeyProvider)?.currentState?.push(
                buildShellPageRoute(
                  const AccountSettingsScreen(),
                  settings: const RouteSettings(name: ShellRoutes.account),
                ),
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'chatbot',
          child: AccountMenuItem(
            icon: Icons.chat_outlined,
            title: 'Chatbot',
            isDestructive: false,
            onTap: () {
              Navigator.pop(context);
              ref.read(shellNavigatorKeyProvider)?.currentState?.push(
                buildChatbotPageRoute(
                  const ChatbotScreen(),
                  settings: const RouteSettings(name: ShellRoutes.chatbot),
                ),
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: AccountMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authService = ref.read(authServiceProvider);

    ValidationDialog.show(
      context,
      title: 'Confirm Logout',
      content: const Text('Are you sure you want to logout?'),
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        try {
          await authService.signOut();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _showAccountMenu(context);
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
