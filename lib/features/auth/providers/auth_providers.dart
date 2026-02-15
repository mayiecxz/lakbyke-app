import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:lakbyke_mobile/features/auth/data/services/auth_service.dart';
import 'package:lakbyke_mobile/features/chatbot/providers/chatbot_providers.dart';

/// Provider for AuthRepository (singleton)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for AuthService. Injects ChatbotRepository for sign-out/session-end cleanup.
final authServiceProvider = Provider<AuthService>((ref) {
  final chatbotRepo = ref.watch(chatbotRepositoryProvider);
  return AuthService(chatbotRepository: chatbotRepo);
});

/// Provider for auth state changes stream
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Provider for current user (computed from auth state)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider that tracks if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
