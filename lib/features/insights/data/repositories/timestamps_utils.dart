// Utilities for extracting and summarizing recent ride timestamps.

import 'package:intl/intl.dart';

List<DateTime> getLast5RideTimestamps(List<Map<String, dynamic>> recentTransactions) {
  final withTs = <DateTime>[];
  for (final t in recentTransactions) {
    final ts = t['timestamp'] as DateTime? ?? t['timeStamp'] as DateTime?;
    if (ts != null) withTs.add(ts);
  }
  withTs.sort((a, b) => b.compareTo(a));
  return withTs.take(5).toList();
}

double averageRideHourFromTimestamps(List<DateTime> timestamps) {
  if (timestamps.isEmpty) return 0.0;
  double sum = 0.0;
  for (final t in timestamps) {
    sum += t.hour + t.minute / 60.0 + t.second / 3600.0;
  }
  return sum / timestamps.length;
}
