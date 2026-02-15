import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/config/secrets_loader.dart';
import 'package:lakbyke_mobile/core/theme/theme.dart';
import 'package:lakbyke_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lakbyke_mobile/features/auth/providers/auth_providers.dart';
import 'package:lakbyke_mobile/features/chatbot/providers/chatbot_providers.dart';
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
          if (_previousUserId != null && user == null) {
            final chatbotRepo = ref.read(chatbotRepositoryProvider);
            await chatbotRepo.deleteChatHistoryForUser(_previousUserId!);
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
