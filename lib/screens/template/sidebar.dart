import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
// assets are re-exported from `constants.dart`; avoid duplicate import
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/screens/main_navigation.dart';
import 'package:lakbyke_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:lakbyke_mobile/widgets/validation_dialog.dart';
import 'package:lakbyke_mobile/screens/template/menu_button.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      barrierDismissible: true,
      barrierLabel: 'Sidebar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOut.transform(animation.value);
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: MediaQuery.of(context).orientation == Orientation.portrait ? 0.6 : 0.3,
                child: Transform.translate(
                  offset: Offset(-30 * (1 - curved), 0),
                  child: Opacity(
                    opacity: curved,
                    child: const _SidebarPanel(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel();

  Widget _menuItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
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
  Widget build(BuildContext context) {
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
                      color: Colors.black.withOpacity(0.6),
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
                          MenuButton(
                            size: 28.0,
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
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
                    _menuItem(context, Icons.directions_bike, AppStrings.dashboard, onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      // Navigate to MainNavigation with dashboard index (0)
                      navigator.pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
                      );
                    }),
                    const Divider(color: Colors.white12, height: 1),
                    _menuItem(context, Icons.info_outline, 'About', onTap: () {
                      Navigator.of(context).pop();
                    }),
                    const Divider(color: Colors.white12, height: 1),
                    _menuItem(context, Icons.logout, 'Logout', onTap: () {
                      final navigator = Navigator.of(context);
                      // Close sidebar first then show confirmation dialog
                      navigator.pop();
                      // Use the NavigatorState's context so we don't reference a
                      // potentially deactivated sidebar widget's context.
                      final activeCtx = navigator.context;
                      // Delay slightly so the sidebar closing animation finishes
                      Future.delayed(const Duration(milliseconds: 200), () {
                        ValidationDialog.show(
                          activeCtx,
                          title: 'Confirm Logout',
                          content: const Text('Are you sure you want to logout?'),
                          confirmLabel: 'Logout',
                          cancelLabel: 'Cancel',
                          onConfirm: () async {
                            // Delete chat history before logout
                            final chatbotService = ChatbotService();
                            await chatbotService.deleteChatHistory();
                            
                            // After confirmation navigate to Onboarding and remove previous routes
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                              (route) => false,
                            );
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
