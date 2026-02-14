import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/home/data/repositories/home_repository.dart';
import 'package:lakbyke_mobile/features/home/data/repositories/metrics_repository.dart';
import 'package:lakbyke_mobile/features/home/domain/models/home_data.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';

/// Provider for MetricsRepository (singleton)
final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  return MetricsRepository();
});

/// Provider for HomeRepository (singleton). Composes TransactionRepository + MetricsRepository.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final metricsRepo = ref.watch(metricsRepositoryProvider);
  return HomeRepository(
    transactionRepository: transactionRepo,
    metricsRepository: metricsRepo,
  );
});

/// THE CRITICAL PROVIDER - Single Firebase stream for all home data
/// This eliminates duplicate listeners. Both HomeScreen and BikeData watch this.
final homeDataStreamProvider = StreamProvider<HomeData?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHomeDataStream();
});

/// Provider for service tag
final serviceTagProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getServiceTag();
});

/// Provider for yesterday's data (for welcome modal)
final yesterdayDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getYesterdayData();
});
