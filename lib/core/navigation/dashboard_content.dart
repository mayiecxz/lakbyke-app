import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:lakbyke_mobile/features/maps/presentation/screens/maps_screen.dart';
import 'package:lakbyke_mobile/features/qr/presentation/screens/qr_scanner_screen.dart';
import 'package:lakbyke_mobile/features/insights/presentation/screens/insights_screen.dart';
import 'package:lakbyke_mobile/features/history/presentation/screens/combined_history_screen.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';

/// Dashboard tab content only (no Scaffold). Used as the initial route of the shell Navigator.
/// Tab state comes from [AppRouteAuthenticated]; callbacks update app router.
class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  static const int historyMainIndex = 4;
  static const int historyTabCount = 2;

  List<Widget> _screens(int currentIndex, int historyTabIndex, ValueChanged<int> onHistoryTabChanged) => [
    const HomeScreen(),
    MapsScreen(isActive: currentIndex == 1),
    QrScannerScreen(isActive: currentIndex == 2),
    const InsightsScreen(),
    CombinedHistoryScreen(
      initialTabIndex: historyTabIndex,
      onTabChanged: onHistoryTabChanged,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(appRouterControllerProvider);
    if (route is! AppRouteAuthenticated) {
      return const SizedBox.shrink();
    }
    final tabIndex = route.tabIndex;
    final historyTabIndex = route.historyTabIndex;
    final notifier = ref.read(appRouterControllerProvider.notifier);

    void onSwipeLeft() {
      if (tabIndex == historyMainIndex) {
        if (historyTabIndex < historyTabCount - 1) {
          notifier.setDashboardHistoryTab(historyTabIndex + 1);
        }
      } else if (tabIndex < 4) {
        notifier.setDashboardTab(tabIndex + 1);
      }
    }

    void onSwipeRight() {
      if (tabIndex == historyMainIndex) {
        if (historyTabIndex > 0) {
          notifier.setDashboardHistoryTab(historyTabIndex - 1);
        } else {
          notifier.setDashboardTab(tabIndex - 1);
        }
      } else if (tabIndex > 0) {
        notifier.setDashboardTab(tabIndex - 1);
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        const threshold = 40.0;
        if (velocity < -threshold) {
          onSwipeLeft();
        } else if (velocity > threshold) {
          onSwipeRight();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(tabIndex),
          index: tabIndex,
          children: _screens(tabIndex, historyTabIndex, notifier.setDashboardHistoryTab),
        ),
      ),
    );
  }
}
