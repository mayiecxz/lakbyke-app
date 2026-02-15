import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/features/insights/data/repositories/insights_repository.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
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

/// Reactive insights data. Use [AsyncValue.when] / [AsyncValue.whenData] in the UI.
/// Errors are surfaced here; listen with [ref.listen] to show a snackbar.
final insightsDataProvider =
    AsyncNotifierProvider<InsightsNotifier, InsightsModel>(InsightsNotifier.new);

class InsightsNotifier extends AsyncNotifier<InsightsModel> {
  @override
  Future<InsightsModel> build() async {
    final repo = ref.read(insightsRepositoryProvider);
    await repo.loadInsightsData();
    return repo.toModel();
  }

  /// Call to refresh (e.g. pull-to-refresh).
  Future<void> refresh() => build();
}
