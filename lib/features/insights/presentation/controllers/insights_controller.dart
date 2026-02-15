import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/providers/insights_repository_providers.dart';

/// Controller for insights screen state. Exposes [InsightsModel] as [AsyncValue].
/// Use [AsyncValue.when] / [AsyncValue.whenData] in the UI.
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
