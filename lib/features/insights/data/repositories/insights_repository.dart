import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_calculations.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_date_utils.dart';
import 'package:lakbyke_mobile/features/insights/domain/insights_model.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/transaction_repository.dart';
import 'package:lakbyke_mobile/features/history/data/repositories/kwh_repository.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/rider_persona.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/unit_health.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/earnings_prediction.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/timestamps_utils.dart';

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
  /// [semesterStart] and [semesterEnd] override the defaults from CBAConstants when provided (e.g. from user settings).
  InsightsModel toModel({DateTime? semesterStart, DateTime? semesterEnd}) {
    final now = DateTime.now();
    final effectiveSemesterStart = semesterStart ?? CBAConstants.semesterStart;
    final effectiveSemesterEnd = semesterEnd ?? CBAConstants.semesterEnd;

    // ---------------------------------------------------------
    // 1. THE INDUSTRY STANDARD FIX: Period-Bounded Filtering
    // ---------------------------------------------------------
    // We create isolated variables specifically for this semester's math
    double semesterEarnings = 0.0;
    Set<String> semesterActiveDates = {};
    int semesterSessions = 0;
    double semesterDurationHours = 0.0;

    for (final t in recentTransactions) {
      final ts = t['timestamp'] as DateTime? ?? t['timeStamp'] as DateTime?;
      if (ts == null) continue;

      // Use your exact utility to filter out past/future transactions!
      if (isTimestampInWindow(ts, effectiveSemesterStart, effectiveSemesterEnd)) {
        semesterEarnings += (t['payout'] as num?)?.toDouble() ?? (t['amount'] as num?)?.toDouble() ?? 0.0;
        semesterActiveDates.add(DateFormat('yyyy-MM-dd').format(ts));
        semesterSessions++;
        semesterDurationHours += ((t['durationSeconds'] as num?)?.toDouble() ?? 0.0) / 3600.0;
      }
    }
    
    final int semesterDaysWithActivity = semesterActiveDates.length;

    // ---------------------------------------------------------
    // 2. ALL-TIME METRICS (ROI & Breakeven)
    // ---------------------------------------------------------
    // Initial investment and Breakeven use ALL-TIME totalEarnings, 
    // because you don't reset the cost of the bike every semester.
    final initialInvestment = _initialCapex;
    final roiProgressPercent = initialInvestment > 0 ? (totalEarnings / initialInvestment) * 100 : 0.0;
    final remainingToBreakeven = math.max(0, initialInvestment - totalEarnings);

    // ---------------------------------------------------------
    // 3. TIME-BOUND METRICS (Semester Projections)
    // ---------------------------------------------------------
    // Calculate the daily average using ONLY the days worked this semester
    final double rawDailyAvg = semesterDaysWithActivity > 0 ? semesterEarnings / semesterDaysWithActivity : 0.0;
    final double dailyAverageEarnings = double.parse(rawDailyAvg.toStringAsFixed(2));

    final estimatedBreakevenDate = InsightsCalculations.estimateBreakevenDate(
      remainingToBreakeven.toDouble(),
      dailyAverageEarnings, // Using current semester pace to predict all-time breakeven is standard practice
      now,
    );

    // Ensure we don't start counting remaining days until the semester actually starts
    final DateTime countingStartDate = now.isBefore(effectiveSemesterStart) ? effectiveSemesterStart : now;
    final remainingSchoolDays = InsightsCalculations.countRemainingSchoolDays(countingStartDate, effectiveSemesterEnd);

    // Calculate remaining potential
    final remainingPotential = dailyAverageEarnings * remainingSchoolDays;
    
    // True Semester Projection = Earned THIS SEMESTER + Remaining Potential THIS SEMESTER
    final projectedSemesterEarnings = semesterEarnings + remainingPotential;

    // Bonus math now uses ONLY this semester's sessions and durations
    final bonusEarningsFor15MinMore = bonusFor15MinMore(
      dailyAverageEarnings, 
      remainingSchoolDays, 
      semesterSessions, 
      semesterDurationHours
    );

    final unitHealthStatus = InsightsCalculations.classifyUnitHealth(totalDistanceKm);
    final (String unitHealthLabel, String unitHealthDescription) = unitHealthLabelAndDescription(unitHealthStatus);

    final last5 = getLast5RideTimestamps(recentTransactions);
    final hasEnoughDataForPersona = last5.length >= 3;
    final riderPersona = InsightsCalculations.classifyRiderPersona(last5);
    final (String riderPersonaName, String riderPersonaAdvice) = riderPersonaNameAndAdvice(riderPersona);
    final averageRideHour = averageRideHourFromTimestamps(last5);
    final displayTag = _mntTag.isEmpty ? 'MNT0001' : _mntTag.toUpperCase();

    return InsightsModel(
      // NOTE: I am passing the isolated `semesterEarnings` into your model's `totalEarnings` field 
      // so your UI breakdown automatically shows the correct "Earned so far this semester" number!
      totalEarnings: semesterEarnings, 
      
      initialInvestment: initialInvestment,
      roiProgressPercent: roiProgressPercent.toDouble(),
      remainingToBreakeven: remainingToBreakeven.toDouble(),
      estimatedBreakevenDate: estimatedBreakevenDate,
      dailyAverageEarnings: dailyAverageEarnings, 
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

  // semester projection now provided by earnings_prediction.dart


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
