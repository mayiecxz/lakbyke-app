import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/insights/presentation/controllers/insights_controller.dart';

export 'package:lakbyke_mobile/features/insights/providers/insights_repository_providers.dart';

/// Reactive insights data. Use [AsyncValue.when] / [AsyncValue.whenData] in the UI.
/// Errors are surfaced here; listen with [ref.listen] to show a snackbar.
final insightsDataProvider =
    AsyncNotifierProvider<InsightsNotifier, InsightsModel>(InsightsNotifier.new);
