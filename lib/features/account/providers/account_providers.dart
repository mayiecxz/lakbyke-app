import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/account/data/repositories/user_repository.dart';

/// Provider for UserRepository (singleton). Use via ref.watch(userRepositoryProvider).
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
