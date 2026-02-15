// Date utilities for insights: calendar-month subtraction and inclusive time windows.

/// Returns [date] minus [months] calendar months (handles year rollover).
/// Example: subtractCalendarMonths(2025-03-15, 1) → 2025-02-15.
DateTime subtractCalendarMonths(DateTime date, int months) {
  if (months == 0) return date;
  int year = date.year;
  int month = date.month - months;
  while (month < 1) {
    month += 12;
    year--;
  }
  while (month > 12) {
    month -= 12;
    year++;
  }
  // Clamp day to last day of target month (e.g. Jan 31 → Feb 28)
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day.clamp(1, lastDay);
  return DateTime(year, month, day);
}

/// True if [timestamp] (date part) is within [startInclusive] and [endInclusive] (date parts).
/// Boundaries are inclusive to avoid excluding transactions exactly on the boundary.
bool isTimestampInWindow(
  DateTime timestamp,
  DateTime startInclusive,
  DateTime endInclusive,
) {
  final t = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final start = DateTime(startInclusive.year, startInclusive.month, startInclusive.day);
  final end = DateTime(endInclusive.year, endInclusive.month, endInclusive.day);
  return !t.isBefore(start) && !t.isAfter(end);
}
