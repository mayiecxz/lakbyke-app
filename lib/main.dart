import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/config/secrets_loader.dart';
import 'package:lakbyke_mobile/core/theme/theme.dart';
import 'package:lakbyke_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SecretsLoader.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to handle cleanup
    Future.microtask(() {
      ref.listenManual(authStateProvider, (previous, next) {
        next.whenData((user) async {
          // If previous user was logged in and current is null, session ended
          if (_previousUserId != null && user == null) {
            final chatbotService = ChatbotService();
            await chatbotService.deleteChatHistoryForUser(_previousUserId!);
          }
          _previousUserId = user?.uid;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LakByke',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const OnboardingScreen(),
    );
  }
}
