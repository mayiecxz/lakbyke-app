import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/app/presentation/controllers/app_router_controller.dart';
import 'package:lakbyke_mobile/features/auth/presentation/screens/login/login_screen.dart';

/// Full-screen login route. Uses router for back; no Navigator.
class LoginRouteScreen extends ConsumerWidget {
  const LoginRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: LoginModal(
        onClose: () => ref.read(appRouterControllerProvider.notifier).goToOnboarding(),
      ),
    );
  }
}
