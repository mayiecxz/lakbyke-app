import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';

void main() {
  group('AppRouterController', () {
    test('initial state is AppRouteOnboarding', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appRouterControllerProvider), isA<AppRouteOnboarding>());
    });

    test('goToLogin sets AppRouteLogin', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToLogin();
      expect(container.read(appRouterControllerProvider), isA<AppRouteLogin>());
    });

    test('goToDashboard sets AppRouteAuthenticated with default tab indices', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToDashboard();
      final route = container.read(appRouterControllerProvider);
      expect(route, isA<AppRouteAuthenticated>());
      expect((route as AppRouteAuthenticated).tabIndex, 0);
      expect(route.historyTabIndex, 0);
    });

    test('goToDashboard with tabIndex and historyTabIndex', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToDashboard(
            tabIndex: 4,
            historyTabIndex: 1,
          );
      final route = container.read(appRouterControllerProvider) as AppRouteAuthenticated;
      expect(route.tabIndex, 4);
      expect(route.historyTabIndex, 1);
    });

    test('setDashboardTab only updates when current route is authenticated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToLogin();
      container.read(appRouterControllerProvider.notifier).setDashboardTab(2);
      expect(container.read(appRouterControllerProvider), isA<AppRouteLogin>());

      container.read(appRouterControllerProvider.notifier).goToDashboard();
      container.read(appRouterControllerProvider.notifier).setDashboardTab(3);
      final route = container.read(appRouterControllerProvider) as AppRouteAuthenticated;
      expect(route.tabIndex, 3);
    });

    test('navigateToHistoryFromDashboard sets tab 4 and history tab index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToDashboard();
      container.read(appRouterControllerProvider.notifier).navigateToHistoryFromDashboard(
            initialTabIndex: 1,
          );
      final route = container.read(appRouterControllerProvider) as AppRouteAuthenticated;
      expect(route.tabIndex, 4);
      expect(route.historyTabIndex, 1);
    });

    test('goToSignup sets AppRouteSignup with serviceTag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToSignup('MNT-123');
      final route = container.read(appRouterControllerProvider) as AppRouteSignup;
      expect(route.serviceTag, 'MNT-123');
    });

    test('goToOnboarding resets to onboarding', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appRouterControllerProvider.notifier).goToDashboard();
      container.read(appRouterControllerProvider.notifier).goToOnboarding();
      expect(container.read(appRouterControllerProvider), isA<AppRouteOnboarding>());
    });
  });
}
