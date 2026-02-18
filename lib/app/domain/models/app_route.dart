/// Central navigation state. No UI imports.
/// Sealed so all cases are exhaustively handled.
sealed class AppRoute {
  const AppRoute();
}

final class AppRouteOnboarding extends AppRoute {
  const AppRouteOnboarding();
}

final class AppRouteLogin extends AppRoute {
  const AppRouteLogin();
}

final class AppRouteSignupQr extends AppRoute {
  const AppRouteSignupQr();
}

final class AppRouteSignup extends AppRoute {
  const AppRouteSignup({required this.serviceTag});
  final String serviceTag;
}

/// Authenticated app: one persistent shell; tab state for dashboard when visible.
final class AppRouteAuthenticated extends AppRoute {
  const AppRouteAuthenticated({
    this.tabIndex = 0,
    this.historyTabIndex = 0,
  });
  final int tabIndex;
  final int historyTabIndex;
}
