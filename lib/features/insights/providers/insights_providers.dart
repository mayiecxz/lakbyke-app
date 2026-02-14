import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/insights_repository.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';

/// Provider for InsightsRepository (auto-dispose when not watched)
final insightsRepositoryProvider = Provider.autoDispose<InsightsRepository>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final kwhRepo = ref.watch(kwhRepositoryProvider);
  return InsightsRepository(
    transactionRepository: transactionRepo,
    kwhRepository: kwhRepo,
  );
});
