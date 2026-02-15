import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/features/insights/data/repositories/insights_repository.dart';
import 'package:lakbyke_mobile/features/insights/data/semester_config_storage.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
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
