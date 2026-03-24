import 'package:intl/intl.dart';

import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';

/// Immutable snapshot for the redesigned insights screen: Investment Recovery,
/// Predictive Modeling, Unit Health, and Rider Persona. Built by [InsightsRepository].
class InsightsModel {
  const InsightsModel({
    required this.totalEarnings,
    required this.initialInvestment,
    required this.roiProgressPercent,
    required this.remainingToBreakeven,
    required this.estimatedBreakevenDate,
    required this.dailyAverageEarnings,
    required this.projectedSemesterEarnings,
    required this.semesterEndDate,
    required this.remainingSchoolDays,
    required this.bonusEarningsFor15MinMore,
    required this.totalDistanceKm,
    required this.unitHealthStatus,
    required this.unitHealthLabel,
    required this.unitHealthDescription,
    required this.mntTag,
    required this.riderPersona,
    required this.riderPersonaName,
    required this.riderPersonaAdvice,
    required this.averageRideHour,
    required this.peakStationHour,
    required this.recentRideTimestamps,
    required this.hasEnoughDataForPersona,
    required this.unlockedPersonas,
  });

  // --- Investment Recovery (Hero Card) ---
  final double totalEarnings;
  final double initialInvestment;
  final double roiProgressPercent;
  final double remainingToBreakeven;
  final DateTime? estimatedBreakevenDate;
  final double dailyAverageEarnings;

  // --- Forecaster (Predictive Modeling) ---
  final double projectedSemesterEarnings;
  final DateTime semesterEndDate;
  final int remainingSchoolDays;
  final double bonusEarningsFor15MinMore;

  // --- Unit Health (Asset Management) ---
  final double totalDistanceKm;
  final String unitHealthStatus;
  final String unitHealthLabel;
  final String unitHealthDescription;
  final String mntTag;

  // --- Rider Persona (Behavioral Analysis) ---
  final String riderPersona;
  final String riderPersonaName;
  final String riderPersonaAdvice;
  final double averageRideHour;
  final int peakStationHour;
  final List<DateTime> recentRideTimestamps;
  final bool hasEnoughDataForPersona;
  final List<String> unlockedPersonas;

  bool get hasRecoveredInvestment => roiProgressPercent >= CBAConstants.cyclistRoiRecoveredPercent;

  String get breakevenDateFormatted {
    if (hasRecoveredInvestment) return 'Already recovered!';
    if (estimatedBreakevenDate == null) return 'Start riding to see your breakeven date.';
    return 'On track to break even by ${DateFormat('MMMM yyyy').format(estimatedBreakevenDate!)}';
  }

  String get roiProgressFormatted => roiProgressPercent.toStringAsFixed(1);

  /// Average ride time as "7:30 AM" style string.
  String get averageRideTimeFormatted {
    if (!averageRideHour.isFinite) return '--';
    final h = averageRideHour.floor() % 24;
    final m = ((averageRideHour - averageRideHour.floor()) * 60).round() % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat.jm().format(dt);
  }
}
