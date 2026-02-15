import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_calculations.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/transaction_repository.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/kwh_repository.dart';

/// Repository for insights data and calculations.
/// Uses TransactionRepository and KwhRepository (single source of truth).
class InsightsRepository {
  InsightsRepository({
    required TransactionRepository transactionRepository,
    required KwhRepository kwhRepository,
  })  : _transactionRepository = transactionRepository,
        _kwhRepository = kwhRepository;

  final TransactionRepository _transactionRepository;
  final KwhRepository _kwhRepository;

  static const double _initialCapex = CBAConstants.cyclistCapex;

  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> kwhHistory = [];

  int totalSessions = 0;
  int daysWithActivity = 0;
  double totalEarnings = 0.0;
  double totalEnergyWh = 0.0;
  double totalDistanceKm = 0.0;
  double totalDurationHours = 0.0;
  double averageEarningsPerSession = 0.0;
  double weeklyAverageEarnings = 0.0;
  double weeklyAverageDistance = 0.0;
  int sessionsPerWeek = 1;

  String _mntTag = '';

  /// Load all insights data from Firebase.
  Future<void> loadInsightsData() async {
    try {
      recentTransactions = await _transactionRepository.getAllTransactions();
      final tag = await _transactionRepository.getServiceTag();
      _mntTag = tag?.trim().isNotEmpty == true ? tag!.trim() : '';

      try {
        kwhHistory = await _kwhRepository.getHistoryData();
      } catch (_) {
        kwhHistory = [];
      }

      calculateHistoricalAverages();
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  /// Build an immutable snapshot for the UI. Call after [loadInsightsData].
  /// [semesterEnd] overrides the default from CBAConstants when provided (e.g. from user settings).
  InsightsModel toModel({DateTime? semesterEnd}) {
    final initialInvestment = _initialCapex;
    final roiProgressPercent =
        initialInvestment > 0 ? (totalEarnings / initialInvestment) * 100 : 0.0;
    final remainingToBreakeven = math.max(0, initialInvestment - totalEarnings);
    final dailyAverageEarnings =
        daysWithActivity > 0 ? totalEarnings / daysWithActivity : 0.0;

    final now = DateTime.now();
    final effectiveSemesterEnd = semesterEnd ?? CBAConstants.semesterEnd;
    final estimatedBreakevenDate = InsightsCalculations.estimateBreakevenDate(
      remainingToBreakeven.toDouble(),
      dailyAverageEarnings,
      now,
    );
    final remainingSchoolDays =
        InsightsCalculations.countRemainingSchoolDays(now, effectiveSemesterEnd);
    final projectedSemesterEarnings =
        _projectSemesterEarnings(dailyAverageEarnings, remainingSchoolDays);
    final bonusEarningsFor15MinMore =
        _bonusFor15MinMore(dailyAverageEarnings, remainingSchoolDays);

    final unitHealthStatus = InsightsCalculations.classifyUnitHealth(totalDistanceKm);
    final (String unitHealthLabel, String unitHealthDescription) =
        _unitHealthLabelAndDescription(unitHealthStatus);

    final last5 = _getLast5RideTimestamps();
    final hasEnoughDataForPersona = last5.length >= 3;
    final riderPersona = InsightsCalculations.classifyRiderPersona(last5);
    final (String riderPersonaName, String riderPersonaAdvice) =
        _riderPersonaNameAndAdvice(riderPersona);
    final averageRideHour = _averageRideHour(last5);

    final displayTag = _mntTag.isEmpty ? 'MNT0001' : _mntTag.toUpperCase();

    return InsightsModel(
      totalEarnings: totalEarnings,
      initialInvestment: initialInvestment,
      roiProgressPercent: roiProgressPercent.toDouble(),
      remainingToBreakeven: remainingToBreakeven.toDouble(),
      estimatedBreakevenDate: estimatedBreakevenDate,
      dailyAverageEarnings: dailyAverageEarnings.toDouble(),
      projectedSemesterEarnings: projectedSemesterEarnings,
      semesterEndDate: effectiveSemesterEnd,
      remainingSchoolDays: remainingSchoolDays,
      bonusEarningsFor15MinMore: bonusEarningsFor15MinMore,
      totalDistanceKm: totalDistanceKm,
      unitHealthStatus: unitHealthStatus,
      unitHealthLabel: unitHealthLabel,
      unitHealthDescription: unitHealthDescription,
      mntTag: displayTag,
      riderPersona: riderPersona,
      riderPersonaName: riderPersonaName,
      riderPersonaAdvice: riderPersonaAdvice,
      averageRideHour: averageRideHour,
      peakStationHour: 12,
      recentRideTimestamps: last5,
      hasEnoughDataForPersona: hasEnoughDataForPersona,
    );
  }

  double _projectSemesterEarnings(double dailyAverageEarnings, int remainingSchoolDays) {
    return dailyAverageEarnings * remainingSchoolDays;
  }

  double _bonusFor15MinMore(double dailyAverageEarnings, int remainingSchoolDays) {
    if (totalSessions <= 0 || totalDurationHours <= 0) return 0.0;
    final avgSessionMinutes = (totalDurationHours * 60) / totalSessions;
    if (avgSessionMinutes <= 0) return 0.0;
    final earningRatePerMinute = dailyAverageEarnings / avgSessionMinutes;
    return earningRatePerMinute * 15 * remainingSchoolDays;
  }

  (String, String) _unitHealthLabelAndDescription(String status) {
    switch (status) {
      case 'excellent':
        return ('Condition: Excellent', 'No maintenance actions needed.');
      case 'bolt_check':
        return (
          'Maintenance Due: Check Mounting Bolts',
          'Have a technician verify mounting bolts for safety.',
        );
      case 'motor_inspection':
        return (
          'Maintenance Due: Inspect Motor Brushes',
          'Schedule motor brush inspection to maintain performance.',
        );
      default:
        return ('Condition: Unknown', 'No maintenance actions needed.');
    }
  }

  List<DateTime> _getLast5RideTimestamps() {
    final withTs = <DateTime>[];
    for (final t in recentTransactions) {
      final ts = t['timestamp'] as DateTime? ?? t['timeStamp'] as DateTime?;
      if (ts != null) withTs.add(ts);
    }
    withTs.sort((a, b) => b.compareTo(a));
    return withTs.take(5).toList();
  }

  double _averageRideHour(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 0.0;
    double sum = 0.0;
    for (final t in timestamps) {
      sum += t.hour + t.minute / 60.0 + t.second / 3600.0;
    }
    return sum / timestamps.length;
  }

  (String, String) _riderPersonaNameAndAdvice(String persona) {
    switch (persona) {
      case 'early_bird':
        return (
          'Early Bird',
          'Ride early to stay cool and beat the midday rush.',
        );
      case 'peak_provider':
        return (
          'Peak Provider',
          'You ride when the station is busiest—great for earning.',
        );
      case 'sunset_cruiser':
        return (
          'Sunset Cruiser',
          'Evening rides help you wind down and still contribute.',
        );
      default:
        return (
          'Unknown',
          'Complete at least 3 rides to unlock your Rider Persona.',
        );
    }
  }

  void resetData() {
    totalSessions = 0;
    daysWithActivity = 0;
    totalEarnings = 0.0;
    totalEnergyWh = 0.0;
    totalDistanceKm = 0.0;
    totalDurationHours = 0.0;
    averageEarningsPerSession = 0.0;
    weeklyAverageEarnings = 0.0;
    weeklyAverageDistance = 0.0;
    sessionsPerWeek = 1;
  }

  void calculateHistoricalAverages() {
    if (recentTransactions.isEmpty && kwhHistory.isEmpty) {
      resetData();
      return;
    }

    final Map<String, List<Map<String, dynamic>>> transactionsByDate = {};
    final Set<String> uniqueDates = {};

    for (final transaction in recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp == null) continue;

      final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
      uniqueDates.add(dateKey);

      transactionsByDate.putIfAbsent(dateKey, () => []).add(transaction);
    }

    double sumEarnings = 0.0;
    double sumEnergy = 0.0;
    double sumDistance = 0.0;
    double sumDurationHours = 0.0;

    for (final transaction in recentTransactions) {
      final payout = (transaction['payout'] as num?)?.toDouble() ??
          (transaction['amount'] as num?)?.toDouble() ??
          0.0;
      sumEarnings += payout;

      final powerSubmittedAh = (transaction['powerSubmitted_Ah'] as num?)?.toDouble() ??
          (transaction['powerSubmitted'] as num?)?.toDouble() ??
          0.0;
      final voltage = (transaction['voltage'] as num?)?.toDouble() ?? 0.0;
      if (voltage > 0 && powerSubmittedAh > 0) {
        sumEnergy += powerSubmittedAh * voltage;
      }

      final durationSec = (transaction['durationSeconds'] as num?)?.toDouble() ?? 0.0;
      sumDurationHours += durationSec / 3600.0;
    }

    for (final record in kwhHistory) {
      final d = (record['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
      sumDistance += d;
    }

    final daysCount = uniqueDates.length;
    final sessionsCount = recentTransactions.length;

    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    final recentList = recentTransactions.where((t) {
      final ts = t['timestamp'] as DateTime? ?? t['timeStamp'] as DateTime?;
      return ts != null && ts.isAfter(fourWeeksAgo);
    }).toList();

    final recentKwh = kwhHistory.where((r) {
      final ts = r['timestamp'] as DateTime?;
      return ts != null && ts.isAfter(fourWeeksAgo);
    }).toList();

    double weeklyEarnings = 0.0;
    double weeklyDistance = 0.0;
    int recentWeeks = 1;

    if (recentList.isNotEmpty || recentKwh.isNotEmpty) {
      final weeksData = <int, List<Map<String, dynamic>>>{};
      for (final transaction in recentList) {
        final ts = transaction['timestamp'] as DateTime? ??
            transaction['timeStamp'] as DateTime?;
        if (ts == null) continue;
        final weeksSince = now.difference(ts).inDays ~/ 7;
        if (weeksSince < 4) {
          weeksData.putIfAbsent(weeksSince, () => []).add(transaction);
        }
      }
      recentWeeks = weeksData.isEmpty ? 1 : weeksData.length;
      for (final transaction in recentList) {
        final payout = (transaction['payout'] as num?)?.toDouble() ??
            (transaction['amount'] as num?)?.toDouble() ??
            0.0;
        weeklyEarnings += payout;
      }
      for (final record in recentKwh) {
        weeklyDistance += (record['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
      }
    }

    totalSessions = sessionsCount;
    daysWithActivity = daysCount;
    totalEarnings = sumEarnings;
    totalEnergyWh = sumEnergy;
    totalDistanceKm = sumDistance;
    totalDurationHours = sumDurationHours;
    averageEarningsPerSession =
        sessionsCount > 0 ? sumEarnings / sessionsCount : 0.0;
    weeklyAverageEarnings = recentWeeks > 0 ? weeklyEarnings / recentWeeks : 0.0;
    weeklyAverageDistance =
        recentWeeks > 0 ? weeklyDistance / recentWeeks : 0.0;

    if (daysCount > 0) {
      sessionsPerWeek = (daysCount / 7).ceil().clamp(1, 7);
    }
  }
}
