import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';

final appRouterControllerProvider =
    NotifierProvider<AppRouterController, AppRoute>(AppRouterController.new);

class AppRouterController extends Notifier<AppRoute> {
  @override
  AppRoute build() => const AppRouteOnboarding();

  void goToOnboarding() => state = const AppRouteOnboarding();
  void goToLogin() => state = const AppRouteLogin();
  void goToSignupQr() => state = const AppRouteSignupQr();
  void goToSignup(String serviceTag) => state = AppRouteSignup(serviceTag: serviceTag);

  /// Enter authenticated shell (persistent). In-shell navigation uses shell Navigator push/pop.
  void goToDashboard({int tabIndex = 0, int historyTabIndex = 0}) {
    state = AppRouteAuthenticated(
      tabIndex: tabIndex.clamp(0, 4),
      historyTabIndex: historyTabIndex.clamp(0, 1),
    );
  }

  void setDashboardTab(int tabIndex) {
    final current = state;
    if (current is AppRouteAuthenticated) {
      state = AppRouteAuthenticated(
        tabIndex: tabIndex.clamp(0, 4),
        historyTabIndex: current.historyTabIndex,
      );
    }
  }

  void setDashboardHistoryTab(int historyTabIndex) {
    final current = state;
    if (current is AppRouteAuthenticated) {
      state = AppRouteAuthenticated(
        tabIndex: current.tabIndex,
        historyTabIndex: historyTabIndex.clamp(0, 1),
      );
    }
  }

  void navigateToHistoryFromDashboard({int initialTabIndex = 0}) {
    goToDashboard(tabIndex: 4, historyTabIndex: initialTabIndex.clamp(0, 1));
  }
}
