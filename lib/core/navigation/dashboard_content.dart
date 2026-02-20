import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart';
import 'package:lakbyke_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:lakbyke_mobile/features/maps/presentation/screens/maps_screen.dart';
import 'package:lakbyke_mobile/features/qr/presentation/screens/qr_scanner_screen.dart';
import 'package:lakbyke_mobile/features/insights/presentation/screens/insights_screen.dart';
import 'package:lakbyke_mobile/features/history/presentation/screens/combined_history_screen.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';

/// Dashboard tab content only (no Scaffold). Used as the initial route of the shell Navigator.
/// Tab state comes from [AppRouteAuthenticated]; PageView slides between tabs.
class DashboardContent extends ConsumerStatefulWidget {
  const DashboardContent({super.key});

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent> {
  static const int _tabCount = 5;
  late PageController _pageController;

  static List<Widget> _screens(
    int currentIndex,
    int historyTabIndex,
    ValueChanged<int> onHistoryTabChanged,
  ) =>
      [
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
  void initState() {
    super.initState();
    final route = ref.read(appRouterControllerProvider);
    final initialIndex = route is AppRouteAuthenticated
        ? route.tabIndex.clamp(0, _tabCount - 1)
        : 0;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(appRouterControllerProvider);
    if (route is! AppRouteAuthenticated) {
      return const SizedBox.shrink();
    }
    final tabIndex = route.tabIndex;
    final historyTabIndex = route.historyTabIndex;
    final notifier = ref.read(appRouterControllerProvider.notifier);

    // When tab changed from outside (e.g. bottom nav tap), animate PageView to that page.
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != tabIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_pageController.hasClients) return;
          _pageController.animateToPage(
            tabIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }

    // Single fixed header below safe area; PageView content transitions underneath.
    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        children: [
          const Header(),
          Expanded(
            child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              notifier.setDashboardTab(index);
            },
            children: _screens(tabIndex, historyTabIndex, notifier.setDashboardHistoryTab),
          ),
        ),
      ],
    ),
    );
  }
}
