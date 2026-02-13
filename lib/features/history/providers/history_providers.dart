import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/transaction_repository.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/kwh_repository.dart';

/// Provider for TransactionRepository (singleton)
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Provider for KwhRepository (singleton)
final kwhRepositoryProvider = Provider<KwhRepository>((ref) {
  return KwhRepository();
});

/// Provider for all transactions (auto-dispose when not watched)
final allTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAllTransactions();
});

/// Provider for kwh history (auto-dispose when not watched)
final kwhHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(kwhRepositoryProvider);
  return repo.getHistoryData();
});

/// Provider for total redeemed amount
final totalRedeemedProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTotalRedeemed();
});

/// Provider for total generated power
final totalGeneratedProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTotalGenerated();
});

/// Provider for battery exchange count
final batteryExchangeCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getBatteryExchangeCount();
});

/// Provider for total kWh generated
final totalKwhGeneratedProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(kwhRepositoryProvider);
  return repo.getTotalKwhGenerated();
});

/// Provider for total distance
final totalDistanceKmProvider = FutureProvider.autoDispose<double>((ref) async {
  final repo = ref.watch(kwhRepositoryProvider);
  return repo.getTotalDistanceKm();
});

/// Provider for aggregated transaction data by filter
final aggregatedTransactionDataProvider = FutureProvider.autoDispose.family<
    List<Map<String, dynamic>>, String>((ref, filter) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAggregatedData(filter);
});

/// Provider for aggregated kwh data by filter
final aggregatedKwhDataProvider = FutureProvider.autoDispose.family<
    List<Map<String, dynamic>>, String>((ref, filter) async {
  final repo = ref.watch(kwhRepositoryProvider);
  return repo.getAggregatedData(filter);
});
