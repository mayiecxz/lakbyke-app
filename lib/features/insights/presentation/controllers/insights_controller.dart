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
    // Grab BOTH the start and end dates from the providers
    final semesterStart = await ref.watch(effectiveSemesterStartProvider.future);
    final semesterEnd = await ref.watch(effectiveSemesterEndProvider.future);

    // Pass both dates to the repository
    return repo.toModel(semesterStart: semesterStart, semesterEnd: semesterEnd);
  }

  /// Call to refresh (e.g. pull-to-refresh).
  Future<void> refresh() => build();
}
