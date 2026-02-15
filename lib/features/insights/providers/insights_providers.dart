import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/features/insights/data/repositories/insights_repository.dart';
import 'package:lakbyke_mobile/features/insights/data/semester_config_storage.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
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

/// Effective semester end: custom from storage if set, else [CBAConstants.semesterEnd].
/// Invalidate after saving in the semester setup modal to refresh insights.
final effectiveSemesterEndProvider = FutureProvider<DateTime>((ref) async {
  final custom = await SemesterConfigStorage.loadSemesterEnd();
  return custom ?? CBAConstants.semesterEnd;
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
    final semesterEnd = await ref.watch(effectiveSemesterEndProvider.future);
    return repo.toModel(semesterEnd: semesterEnd);
  }

  /// Call to refresh (e.g. pull-to-refresh).
  Future<void> refresh() => build();
}
