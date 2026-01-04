import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
// assets are re-exported from `constants.dart`; avoid duplicate import
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/screens/history/kwh_history_screen.dart';
import 'package:lakbyke_mobile/screens/history/transaction_history_screen.dart';
import 'package:lakbyke_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:lakbyke_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:lakbyke_mobile/widgets/validation_dialog.dart';
import 'package:lakbyke_mobile/screens/template/menu_button.dart';

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
  const _SidebarPanel({Key? key}) : super(key: key);

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
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    _menuItem(context, Icons.directions_bike, AppStrings.dashboard, onTap: () {
                                      final navigator = Navigator.of(context);
                                      navigator.pop();
                                      navigator.push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                    }),
                    
                    _menuItem(context, Icons.battery_std, 'kWh History', onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(MaterialPageRoute(
                        builder: (_) => const KwhHistoryScreen(),
                      ));
                    }),
                    
                    _menuItem(context, Icons.list_alt, 'Transaction History', onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ));
                    }),
                    
                    _menuItem(context, Icons.info_outline, 'About', onTap: () {
                      Navigator.of(context).pop();
                    }),
                    
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
                          onConfirm: () {
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
                    // Place lakbike_logo5 between logout and bottom, centered and sized to sidebar width
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final sidebarWidth = MediaQuery.of(context).size.width * (MediaQuery.of(context).orientation == Orientation.portrait ? 0.6 : 0.3);
                        return Container(
                          width: sidebarWidth,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 24.0),
                          child: Image.asset(
                            'assets/images/lakbike_logo5.png',
                            width: sidebarWidth * 0.8,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
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
