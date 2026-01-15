import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/theme.dart';
import 'package:lakbyke_mobile/screens/onboarding/onboarding_screen.dart';
import 'package:lakbyke_mobile/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authService.initializeAuthListener();
  }

  @override
  void dispose() {
    _authService.disposeAuthListener();
    super.dispose();
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
