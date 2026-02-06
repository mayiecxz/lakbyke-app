import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/services/transaction_service.dart';
import 'package:lakbyke_mobile/services/kwh_service.dart';

/// Model class for insights data and calculations
class InsightsModel {
  final TransactionService _transactionService = TransactionService();
  final KwhService _kwhService = KwhService();

  // Insights data
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> kwhHistory = [];

  // Insights settings
  int sessionsPerWeek = 1;
  double averageEarningsPerSession = 0.0;
  double averageEnergyPerSession = 0.0; // in Wh
  double averageDistancePerSession = 0.0; // in km
  double currentMonthlyProjection = 0.0;
  double projectedMonthlyEarnings = 0.0;
  double projectedMonthlyEnergy = 0.0; // in Wh
  double projectedMonthlyDistance = 0.0; // in km

  // Historical data from Firebase
  double weeklyAverageEarnings = 0.0;
  double weeklyAverageDistance = 0.0;
  int totalSessions = 0;
  int daysWithActivity = 0;

  // Analytics chart filter
  String analyticsFilter = 'past week';

  /// Load all insights data from Firebase.
  /// Transactions: from "transactions" table, filtered by current user's mntTag (service tag).
  /// KWH history: from "deviceEnergyData" table, filtered by mntTag.
  Future<void> loadInsightsData() async {
    try {
      // Load transactions from Firebase (filtered by user's service tag / mntTag)
      recentTransactions = await _transactionService.getAllTransactions();

      // Load KWH history from Firebase deviceEnergyData (filtered by mntTag)
      try {
        kwhHistory = await _kwhService.getHistoryData();
      } catch (e) {
        // Continue without KWH history
        kwhHistory = [];
      }

      // Calculate historical averages from real Firebase data
      calculateHistoricalAverages();

      // Calculate projections
      calculateProjections();
    } catch (e) {
      // Handle error - data will remain at default values
    }
  }

  /// Calculate historical averages from transactions and KWH history
  void calculateHistoricalAverages() {
    if (recentTransactions.isEmpty && kwhHistory.isEmpty) {
      totalSessions = 0;
      daysWithActivity = 0;
      weeklyAverageEarnings = 0.0;
      weeklyAverageDistance = 0.0;
      averageEarningsPerSession = 0.0;
      averageEnergyPerSession = 0.0;
      averageDistancePerSession = 0.0;
      return;
    }

    // Group transactions by date
    final Map<String, List<Map<String, dynamic>>> transactionsByDate = {};
    final Set<String> uniqueDates = {};

    for (var transaction in recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp == null) continue;

      final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
      uniqueDates.add(dateKey);

      if (!transactionsByDate.containsKey(dateKey)) {
        transactionsByDate[dateKey] = [];
      }
      transactionsByDate[dateKey]!.add(transaction);
    }

    // Calculate totals from transactions
    double totalEarnings = 0.0;
    double totalEnergy = 0.0; // in Wh
    double totalDistance = 0.0; // in km

    for (var transaction in recentTransactions) {
      // Earnings from payout
      final payout = transaction['payout'] as double? ??
          transaction['amount'] as double? ??
          0.0;
      totalEarnings += payout;

      // Energy from powerSubmitted_Ah and voltage (convert Ah to Wh)
      final powerSubmittedAh = transaction['powerSubmitted_Ah'] as double? ??
          transaction['powerSubmitted'] as double? ??
          0.0;
      final voltage = transaction['voltage'] as double? ?? 0.0;
      if (voltage > 0 && powerSubmittedAh > 0) {
        totalEnergy += powerSubmittedAh * voltage; // Convert Ah to Wh
      }
    }

    // Calculate distance from KWH history (deviceEnergyData)
    for (var record in kwhHistory) {
      final distance = record['totalDistanceKm'] as double? ?? 0.0;
      totalDistance += distance;
    }

    // Calculate averages
    final daysWithActivityCount = uniqueDates.length;
    final totalSessionsCount = recentTransactions.length;

    // Calculate weekly average (last 4 weeks or all time)
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    final recentTransactionsList = recentTransactions.where((t) {
      final timestamp = t['timestamp'] as DateTime? ??
          t['timeStamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(fourWeeksAgo);
    }).toList();

    final recentKwhHistoryList = kwhHistory.where((r) {
      final timestamp = r['timestamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(fourWeeksAgo);
    }).toList();

    double weeklyEarnings = 0.0;
    double weeklyDistance = 0.0;
    int recentWeeks = 1; // Default to 1 week if no recent data

    if (recentTransactionsList.isNotEmpty || recentKwhHistoryList.isNotEmpty) {
      // Calculate average per week over last 4 weeks
      final weeksData = <int, List<Map<String, dynamic>>>{};
      for (var transaction in recentTransactionsList) {
        final timestamp = transaction['timestamp'] as DateTime? ??
            transaction['timeStamp'] as DateTime?;
        if (timestamp == null) continue;

        final weeksSince = now.difference(timestamp).inDays ~/ 7;
        if (weeksSince < 4) {
          if (!weeksData.containsKey(weeksSince)) {
            weeksData[weeksSince] = [];
          }
          weeksData[weeksSince]!.add(transaction);
        }
      }

      recentWeeks = weeksData.isEmpty ? 1 : weeksData.length;

      // Calculate weekly totals
      for (var transaction in recentTransactionsList) {
        final payout = transaction['payout'] as double? ??
            transaction['amount'] as double? ??
            0.0;
        weeklyEarnings += payout;
      }

      // Calculate weekly distance from recent KWH history
      for (var record in recentKwhHistoryList) {
        final distance = record['totalDistanceKm'] as double? ?? 0.0;
        weeklyDistance += distance;
      }
    }

    // Calculate average per session
    final avgEarningsPerSession =
        totalSessionsCount > 0 ? totalEarnings / totalSessionsCount : 0.0;
    final avgEnergyPerSession =
        totalSessionsCount > 0 ? totalEnergy / totalSessionsCount : 0.0;
    final avgDistancePerSession =
        totalSessionsCount > 0 ? totalDistance / totalSessionsCount : 0.0;

    // Calculate weekly average (divide by number of weeks)
    final weeklyAvgEarnings =
        recentWeeks > 0 ? weeklyEarnings / recentWeeks : 0.0;
    final weeklyAvgDistance =
        recentWeeks > 0 ? weeklyDistance / recentWeeks : 0.0;

    // Update model properties
    totalSessions = totalSessionsCount;
    daysWithActivity = daysWithActivityCount;
    averageEarningsPerSession = avgEarningsPerSession;
    averageEnergyPerSession = avgEnergyPerSession;
    averageDistancePerSession = avgDistancePerSession;
    weeklyAverageEarnings = weeklyAvgEarnings;
    weeklyAverageDistance = weeklyAvgDistance;

    // Set initial sessions per week based on activity
    if (daysWithActivityCount > 0) {
      sessionsPerWeek = (daysWithActivityCount / 7).ceil().clamp(1, 7);
    }
  }

  /// Calculate monthly projections based on sessions per week
  void calculateProjections() {
    // Calculate monthly projection based on sessions per week
    const weeksPerMonth = 4.33; // Average weeks per month
    final sessionsPerMonth = sessionsPerWeek * weeksPerMonth;

    projectedMonthlyEarnings = averageEarningsPerSession * sessionsPerMonth;
    projectedMonthlyEnergy = averageEnergyPerSession * sessionsPerMonth;
    projectedMonthlyDistance = averageDistancePerSession * sessionsPerMonth;

    // Current monthly projection (based on weekly average)
    currentMonthlyProjection = weeklyAverageEarnings * weeksPerMonth;
  }

  /// Calculate analytics data based on selected filter
  /// Returns all data points for the period, including zeros for days/months/years with no data
  List<Map<String, dynamic>> getAnalyticsData() {
    final now = DateTime.now();
    final aggregated = <DateTime, double>{};

    // First, aggregate existing transaction data (even if empty, we'll still generate data points)
    for (final transaction in recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp == null) continue;

      final amount = transaction['payout'] as double? ??
          transaction['amount'] as double? ??
          0.0;

      DateTime key;

      switch (analyticsFilter) {
        case 'past week':
          // Group by day (date only, no time)
          key = DateTime(timestamp.year, timestamp.month, timestamp.day);
          break;
        case 'past month':
          // Group by day (date only, no time)
          key = DateTime(timestamp.year, timestamp.month, timestamp.day);
          break;
        case 'past year':
          // Group by month
          key = DateTime(timestamp.year, timestamp.month);
          break;
        case 'all time':
          // Group by year
          key = DateTime(timestamp.year);
          break;
        default:
          key = DateTime(timestamp.year, timestamp.month, timestamp.day);
      }

      aggregated[key] = (aggregated[key] ?? 0.0) + amount;
    }

    // Generate all data points for the selected period
    List<Map<String, dynamic>> allDataPoints = [];

    switch (analyticsFilter) {
      case 'past week':
        // Generate 7 days (today and 6 days before)
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = DateTime(date.year, date.month, date.day);
          final amount = aggregated[key] ?? 0.0;
          final label = DateFormat('EEE').format(date); // Day abbreviation (Mon, Tue, etc.)

          allDataPoints.add({
            'label': label,
            'amount': amount,
            'date': key,
          });
        }
        break;

      case 'past month':
        // Generate last 30 days (past month)
        for (int i = 29; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = DateTime(date.year, date.month, date.day);
          final amount = aggregated[key] ?? 0.0;
          // Show day number, but for better readability, show abbreviated format for some days
          final label = i == 29 || i == 0 || i % 7 == 0
              ? DateFormat('MMM d').format(date) // Show month and day for first, last, and weekly markers
              : '${date.day}'; // Just day number for others

          allDataPoints.add({
            'label': label,
            'amount': amount,
            'date': key,
          });
        }
        break;

      case 'past year':
        // Generate 12 months (current month and 11 months before)
        for (int i = 11; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          // Handle year rollover
          final adjustedDate = date.month <= 0
              ? DateTime(date.year - 1, date.month + 12, 1)
              : date;
          final key = DateTime(adjustedDate.year, adjustedDate.month);
          final amount = aggregated[key] ?? 0.0;
          final label = DateFormat('MMM').format(adjustedDate); // Month abbreviation

          allDataPoints.add({
            'label': label,
            'amount': amount,
            'date': key,
          });
        }
        break;

      case 'all time':
        // Find first transaction year
        int firstYear = now.year;
        if (recentTransactions.isNotEmpty) {
          for (final transaction in recentTransactions) {
            final timestamp = transaction['timestamp'] as DateTime? ??
                transaction['timeStamp'] as DateTime?;
            if (timestamp != null && timestamp.year < firstYear) {
              firstYear = timestamp.year;
            }
          }
        }

        // Generate all years from first year to current year
        for (int year = firstYear; year <= now.year; year++) {
          final key = DateTime(year);
          final amount = aggregated[key] ?? 0.0;
          final label = year.toString(); // Year as string

          allDataPoints.add({
            'label': label,
            'amount': amount,
            'date': key,
          });
        }
        break;

      default:
        // Default to past week
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = DateTime(date.year, date.month, date.day);
          final amount = aggregated[key] ?? 0.0;
          final label = DateFormat('EEE').format(date);

          allDataPoints.add({
            'label': label,
            'amount': amount,
            'date': key,
          });
        }
    }

    // Sort by date ascending (oldest first for chart)
    allDataPoints.sort((a, b) =>
        (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return allDataPoints;
  }

  /// Check if there's actual data (non-zero amounts) for the current filter period
  bool hasDataForCurrentPeriod() {
    final analyticsData = getAnalyticsData();
    if (analyticsData.isEmpty) return false;
    
    // Check if any data point has a non-zero amount
    return analyticsData.any((dataPoint) => (dataPoint['amount'] as double) > 0);
  }

  /// Check if there's activity in the past week
  bool hasActivityInPastWeek() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    return recentTransactions.any((transaction) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(oneWeekAgo);
    });
  }

  /// Check if there's activity in the past month
  bool hasActivityInPastMonth() {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    
    return recentTransactions.any((transaction) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(oneMonthAgo);
    });
  }

  /// Get a descriptive message for when there's no data for the current period
  String getNoDataMessage() {
    switch (analyticsFilter) {
      case 'past week':
        return 'No earnings data for the past week. Start a session to see your earnings!';
      case 'past month':
        return 'No earnings data for the past month. Start a session to see your earnings!';
      case 'past year':
        return 'No earnings data for the past year. Start a session to see your earnings!';
      case 'all time':
        return 'No earnings data available. Start a session to see your earnings!';
      default:
        return 'No data available';
    }
  }

  /// Helper function to calculate nice rounded numbers for Y-axis (statistical standard)
  static double niceNumber(double range, bool round) {
    if (range == 0) return 1.0;
    final exponent = (math.log(range) / math.ln10).floor();
    final powerOf10 = math.pow(10, exponent).toDouble();
    final fraction = range / powerOf10;
    double niceFraction;

    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }

    return niceFraction * powerOf10;
  }
}
