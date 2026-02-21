import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/authenticated_shell.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/shared/animated_screen_switcher.dart';
import 'package:lakbyke_mobile/app/presentation/screens/login_route_screen.dart';
import 'package:lakbyke_mobile/features/auth/data/services/auth_service.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/signup/signup_qr_screen.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/signup/signup_screen.dart';
import 'package:lakbyke_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Single root UI. Pre-auth: one screen per route. Post-auth: one persistent [AuthenticatedShell].
/// Restores session to dashboard if user is still signed in and last logout was within 1 week.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _syncRouteWithAuth(ref));
  }

  /// When auth state has a user but we're on onboarding/login, restore to dashboard if
  /// last logout was within 1 week (or no logout); otherwise sign out.
  Future<void> _syncRouteWithAuth(WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    final route = ref.read(appRouterControllerProvider);
    if (route is AppRouteAuthenticated) return;

    final authService = ref.read(authServiceProvider);
    if (authService.userChoseLogoutThisSession) return;

    final lastLogoutMs = await authService.getLastLogoutTimestamp();
    if (lastLogoutMs == null) {
      ref.read(appRouterControllerProvider.notifier).goToDashboard();
      return;
    }
    if (AuthService.isWithinOneWeek(lastLogoutMs)) {
      await authService.clearLastLogoutTimestamp();
      if (ref.context.mounted) {
        ref.read(appRouterControllerProvider.notifier).goToDashboard();
      }
    } else {
      await authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) return;
        final route = ref.read(appRouterControllerProvider);
        if (route is AppRouteAuthenticated) return;
        final authService = ref.read(authServiceProvider);
        if (authService.userChoseLogoutThisSession) return;
        _syncRouteWithAuth(ref);
      });
    });

    final route = ref.watch(appRouterControllerProvider);
    final child = switch (route) {
      AppRouteOnboarding() => const OnboardingScreen(),
      AppRouteLogin() => const LoginRouteScreen(),
      AppRouteSignupQr() => SignupQrScreen(
        onVerified: (tag) => ref.read(appRouterControllerProvider.notifier).goToSignup(tag),
      ),
      AppRouteSignup() => SignupScreen(
        serviceTag: route.serviceTag,
        onBack: () => ref.read(appRouterControllerProvider.notifier).goToSignupQr(),
      ),
      AppRouteAuthenticated() => const AuthenticatedShell(),
    };
    final stableKey = route is AppRouteAuthenticated ? 'authenticated' : route.runtimeType.toString();
    return AnimatedScreenSwitcher(
      child: KeyedSubtree(
        key: ValueKey<String>(stableKey),
        child: child,
      ),
    );
  }
}
