import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/domain/models/app_route.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/app/presentation/authenticated_shell.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/animated_screen_switcher.dart';
import 'package:lakbyke_mobile/app/presentation/screens/login_route_screen.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/signup/signup_qr_screen.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/signup/signup_screen.dart';
import 'package:lakbyke_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Single root UI. Pre-auth: one screen per route. Post-auth: one persistent [AuthenticatedShell].
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
