/// Pure calculation helpers for insights (unit-testable without Firebase).
class InsightsCalculations {
  InsightsCalculations._();

  /// Unit health tier from total distance: <500 excellent, 500–<2000 bolt_check, >=2000 motor_inspection.
  static String classifyUnitHealth(double totalDistanceKm) {
    if (totalDistanceKm < 500) return 'excellent';
    if (totalDistanceKm < 2000) return 'bolt_check';
    return 'motor_inspection';
  }

  /// Rider persona from average hour of last rides: 6–10 early_bird, 10–15 peak_provider, 15–20 sunset_cruiser.
  static String classifyRiderPersona(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 'unknown';
    final avgHour = _averageRideHour(timestamps);
    if (avgHour >= 6 && avgHour < 10) return 'early_bird';
    if (avgHour >= 10 && avgHour < 15) return 'peak_provider';
    if (avgHour >= 15 && avgHour < 20) return 'sunset_cruiser';
    return 'unknown';
  }

  static double _averageRideHour(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 0.0;
    double sum = 0.0;
    for (final t in timestamps) {
      sum += t.hour + t.minute / 60.0 + t.second / 3600.0;
    }
    return sum / timestamps.length;
  }

  /// Estimated breakeven date from remaining debt and daily average. Returns null if already recovered or no daily avg.
  static DateTime? estimateBreakevenDate(
    double remainingDebt,
    double dailyAvg, [
    DateTime? now,
  ]) {
    if (dailyAvg <= 0 || remainingDebt <= 0) return null;
    final n = now ?? DateTime.now();
    final days = (remainingDebt / dailyAvg).ceil();
    return n.add(Duration(days: days));
  }

  /// Count weekdays (Mon–Fri) from [from] to [end] (inclusive).
  static int countRemainingSchoolDays(DateTime from, DateTime end) {
    if (from.isAfter(end)) return 0;
    int count = 0;
    var d = DateTime(from.year, from.month, from.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(endDate)) {
      if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }
}
