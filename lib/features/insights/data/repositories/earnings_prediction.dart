// Helpers for projecting semester earnings and estimating bonus for added minutes.

double projectSemesterEarnings(double dailyAverageEarnings, int remainingSchoolDays) {
  return dailyAverageEarnings * remainingSchoolDays;
}

double bonusFor15MinMore(
  double dailyAverageEarnings,
  int remainingSchoolDays,
  int totalSessions,
  double totalDurationHours,
) {
  if (totalSessions <= 0 || totalDurationHours <= 0) return 0.0;
  final avgSessionMinutes = (totalDurationHours * 60) / totalSessions;
  if (avgSessionMinutes <= 0) return 0.0;
  final earningRatePerMinute = dailyAverageEarnings / avgSessionMinutes;
  return earningRatePerMinute * 15 * remainingSchoolDays;
}
