import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/shell_navigator_key.dart'
    show shellNavigatorKeyProvider, shellRouteNameProvider, ShellRouteObserver;
import 'package:lakbyke_mobile/app/presentation/shell_routes.dart'
    show buildChatbotPageRoute, buildShellPageRoute, ShellRoutes;
import 'package:lakbyke_mobile/core/navigation/dashboard_content.dart';
import 'package:lakbyke_mobile/features/account/presentation/screens/account_settings_screen.dart';
import 'package:lakbyke_mobile/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:lakbyke_mobile/features/history/presentation/screens/transaction_detail_screen.dart';
import 'package:lakbyke_mobile/features/history/presentation/screens/kwh_detail_screen.dart';

/// Persistent shell for authenticated app: Scaffold with bottom nav + FAB;
/// body is a nested Navigator. All in-app screens are routes inside this Navigator.
class AuthenticatedShell extends ConsumerStatefulWidget {
  const AuthenticatedShell({super.key});

  @override
  ConsumerState<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends ConsumerState<AuthenticatedShell> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final ShellRouteObserver _routeObserver;

  static const Color _activeColor = Color(0xFF317263);
  static const Color _accentColor = Color(0xFF70D2C8);

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _routeObserver = ShellRouteObserver((name) {
      // Defer to avoid assertion: _elements.contains(element) during Navigator lifecycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(shellRouteNameProvider.notifier).setCurrentRouteName(name);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer provider update to avoid "modify provider while widget tree building"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellNavigatorKeyProvider.notifier).attachKey(_navigatorKey);
    });
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ShellRoutes.dashboard:
      case '/':
        return PageRouteBuilder<void>(
          settings: const RouteSettings(name: ShellRoutes.dashboard),
          pageBuilder: (context, animation, secondaryAnimation) => const DashboardContent(),
          transitionDuration: Duration.zero,
        );
      case ShellRoutes.chatbot:
        return buildChatbotPageRoute(const ChatbotScreen(), settings: settings);
      case ShellRoutes.account:
        return buildShellPageRoute(const AccountSettingsScreen(), settings: settings);
      case ShellRoutes.transactionDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return null;
        return buildShellPageRoute(
          TransactionDetailScreen(
            periodLabel: args['periodLabel'] as String,
            periodDate: args['periodDate'] as DateTime,
            filterType: args['filterType'] as String,
            totalAmount: (args['totalAmount'] as num).toDouble(),
          ),
          settings: settings,
        );
      case ShellRoutes.kwhDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return null;
        return buildShellPageRoute(
          KwhDetailScreen(
            periodLabel: args['periodLabel'] as String,
            periodDate: args['periodDate'] as DateTime,
            filterType: args['filterType'] as String,
            totalEnergy: (args['totalEnergy'] as num).toDouble(),
            totalDistance: (args['totalDistance'] as num).toDouble(),
          ),
          settings: settings,
        );
      default:
        return null;
    }
  }

  void _onTabTapped(int index) {
    final nav = _navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.settings.name == ShellRoutes.dashboard);
    }
    ref.read(appRouterControllerProvider.notifier).setDashboardTab(index);
  }

  void _onFabPressed() {
    final nav = _navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.settings.name == ShellRoutes.dashboard);
    }
    ref.read(appRouterControllerProvider.notifier).setDashboardTab(2);
  }

  static const double _fabExtraBottom = 12;

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(appRouterControllerProvider);
    final topRouteName = ref.watch(shellRouteNameProvider);
    final isChatbotFullScreen = topRouteName == ShellRoutes.chatbot;
    final tabIndex = route is AppRouteAuthenticated ? route.tabIndex : 0;
    final isFabActive = tabIndex == 2;
    final fabBorderColor = isFabActive ? _accentColor : Colors.grey;
    final fabIconColor = isFabActive ? _accentColor : Colors.grey;

    // Header and bottom nav are scaffold slots outside the Navigator, so they stay
    // fixed and are not affected by route or tab transitions (only body content changes).
    return Scaffold(
      extendBody: true,
      body: Navigator(
        key: _navigatorKey,
        initialRoute: ShellRoutes.dashboard,
        onGenerateRoute: _onGenerateRoute,
        observers: [_routeObserver],
      ),
      floatingActionButton: isChatbotFullScreen
          ? null
          : SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: _onFabPressed,
          elevation: 4,
          backgroundColor: Colors.white,
          shape: CircleBorder(
            side: BorderSide(
              color: fabBorderColor,
              width: isFabActive ? 4 : 2,
            ),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 32,
            color: fabIconColor,
          ),
        ),
      ),
      floatingActionButtonLocation: isChatbotFullScreen
          ? null
          : _LowerCenterDocked(_fabExtraBottom),
      bottomNavigationBar: isChatbotFullScreen
          ? null
          : _buildBottomNav(tabIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      height: 80,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavPill(icon: Icons.directions_bike, label: 'Home', index: 0),
            _buildNavPill(icon: Icons.map_outlined, label: 'Maps', index: 1),
            const SizedBox(width: 40),
            _buildNavPill(icon: Icons.trending_up, label: 'Insights', index: 3),
            _buildNavPill(icon: Icons.history, label: 'History', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final route = ref.watch(appRouterControllerProvider);
    final tabIndex = route is AppRouteAuthenticated ? route.tabIndex : 0;
    final isActive = tabIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20.0 : 0.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: isActive ? _activeColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isActive ? _activeColor : Colors.grey.shade500,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? _activeColor : Colors.grey.shade500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Positions the FAB in the center dock, slightly lower than default.
class _LowerCenterDocked extends FloatingActionButtonLocation {
  const _LowerCenterDocked(this.extraBottom);

  final double extraBottom;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final centerX = (geometry.scaffoldSize.width -
            geometry.floatingActionButtonSize.width) /
        2.0;
    final y = geometry.contentBottom -
        geometry.floatingActionButtonSize.height / 2.0 +
        extraBottom;
    return Offset(centerX, y);
  }
}
