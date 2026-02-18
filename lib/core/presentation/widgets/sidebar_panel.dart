import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/responsive_image.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/validation_dialog.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart';
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart'
    show buildChatbotPageRoute, buildShellPageRoute, ShellRoutes;
import 'package:lakbyke_mobile/features/chatbot/presentation/screens/chatbot_screen.dart';

/// Inner panel of the sidebar: logo, close button, and menu items.
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({super.key});

  static Widget menuItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * (MediaQuery.of(context).orientation == Orientation.portrait ? 0.6 : 0.3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28.0),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ResponsiveImage(
                                  assetPath: AppAssets.logoWhite,
                                  maxWidthPercent: 0.4,
                                  minWidth: 80.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12, thickness: 1, height: 1),
                    menuItem(context, Icons.directions_bike, AppStrings.home, onTap: () {
                      Navigator.of(context).pop();
                      ref.read(shellNavigatorKeyProvider)?.currentState?.popUntil(
                        (route) => route.settings.name == ShellRoutes.dashboard,
                      );
                      ref.read(appRouterControllerProvider.notifier).setDashboardTab(0);
                    }),
                    const Divider(color: Colors.white12, height: 1),
                    menuItem(context, Icons.info_outline, 'About', onTap: () {
                      Navigator.of(context).pop();
                    }),
                    const Divider(color: Colors.white12, height: 1),
                    menuItem(context, Icons.chat_outlined, 'Chatbot', onTap: () {
                      Navigator.of(context).pop();
                      ref.read(shellNavigatorKeyProvider)?.currentState?.push(
                        buildChatbotPageRoute(
                          const ChatbotScreen(),
                          settings: const RouteSettings(name: ShellRoutes.chatbot),
                        ),
                      );
                    }),
                    const Divider(color: Colors.white12, height: 1),
                    menuItem(context, Icons.logout, 'Logout', onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (!navigator.mounted) return;
                        final authService = ref.read(authServiceProvider);
                        ValidationDialog.show(
                          navigator.context,
                          title: 'Confirm Logout',
                          content: const Text('Are you sure you want to logout?'),
                          confirmLabel: 'Logout',
                          cancelLabel: 'Cancel',
                          onConfirm: () async {
                            await authService.signOut();
                            if (navigator.mounted) {
                              ref.read(appRouterControllerProvider.notifier).goToOnboarding();
                            }
                          },
                        );
                      });
                    }),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
