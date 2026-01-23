import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/services/transaction_service.dart';
import 'package:lakbyke_mobile/services/kwh_service.dart';
import 'package:intl/intl.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final TransactionService _transactionService = TransactionService();
  final KwhService _kwhService = KwhService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentTransactions = [];
  
  // Prediction settings
  int _sessionsPerWeek = 1;
  double _averageEarningsPerSession = 0.0;
  double _averageEnergyPerSession = 0.0; // in Wh
  double _averageDistancePerSession = 0.0; // in km
  double _currentMonthlyProjection = 0.0;
  double _projectedMonthlyEarnings = 0.0;
  double _projectedMonthlyEnergy = 0.0; // in Wh
  double _projectedMonthlyDistance = 0.0; // in km
  
  // Historical data from Firebase
  double _weeklyAverageEarnings = 0.0;
  double _weeklyAverageDistance = 0.0;
  int _totalSessions = 0;
  int _daysWithActivity = 0;
  
  // Analytics chart filter
  String _analyticsFilter = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadPredictionData();
  }

  Future<void> _loadPredictionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Dashboard data loading removed - not currently used in UI

      // Load transactions from Firebase (transactions/{stationId}/{transaction_id})
      final transactions = await _transactionService.getAllTransactions();
      setState(() {
        _recentTransactions = transactions;
      });

      // Load KWH history from Firebase (deviceEnergyData/{serviceTag}/{document_id})
      // Handle permission errors gracefully - continue even if history can't be loaded
      List<Map<String, dynamic>> kwhHistory = [];
      try {
        kwhHistory = await _kwhService.getHistoryData();
        setState(() {
        });
      } catch (e) {
        // Continue without KWH history - app can still function with transaction data
        setState(() {
        });
      }

      // Calculate historical averages from real Firebase data
      _calculateHistoricalAverages(transactions, kwhHistory);

      // Calculate projections
      _calculateProjections();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateHistoricalAverages(
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> kwhHistory,
  ) {
    if (transactions.isEmpty && kwhHistory.isEmpty) {
      setState(() {
        _totalSessions = 0;
        _daysWithActivity = 0;
        _weeklyAverageEarnings = 0.0;
        _weeklyAverageDistance = 0.0;
        _averageEarningsPerSession = 0.0;
        _averageEnergyPerSession = 0.0;
        _averageDistancePerSession = 0.0;
      });
      return;
    }

    // Group transactions by date
    final Map<String, List<Map<String, dynamic>>> transactionsByDate = {};
    final Set<String> uniqueDates = {};

    for (var transaction in transactions) {
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

    for (var transaction in transactions) {
      // Earnings from payout
      final payout = transaction['payout'] as double? ?? 
                     transaction['amount'] as double? ?? 0.0;
      totalEarnings += payout;

      // Energy from powerSubmitted_Ah and voltage (convert Ah to Wh)
      final powerSubmittedAh = transaction['powerSubmitted_Ah'] as double? ?? 
                               transaction['powerSubmitted'] as double? ?? 0.0;
      final voltage = transaction['voltage'] as double? ?? 0.0;
      if (voltage > 0 && powerSubmittedAh > 0) {
        totalEnergy += powerSubmittedAh * voltage; // Convert Ah to Wh
      }
    }

    // Calculate distance from KWH history (deviceEnergyData)
    // Sum distance from all history records
    for (var record in kwhHistory) {
      final distance = record['totalDistanceKm'] as double? ?? 0.0;
      totalDistance += distance;
    }

    // Calculate averages
    final daysWithActivity = uniqueDates.length;
    final totalSessions = transactions.length;
    
    // Calculate weekly average (last 4 weeks or all time)
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    
    final recentTransactions = transactions.where((t) {
      final timestamp = t['timestamp'] as DateTime? ?? t['timeStamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(fourWeeksAgo);
    }).toList();

    final recentKwhHistory = kwhHistory.where((r) {
      final timestamp = r['timestamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(fourWeeksAgo);
    }).toList();

    double weeklyEarnings = 0.0;
    double weeklyDistance = 0.0;
    int recentWeeks = 1; // Default to 1 week if no recent data

    if (recentTransactions.isNotEmpty || recentKwhHistory.isNotEmpty) {
      // Calculate average per week over last 4 weeks
      final weeksData = <int, List<Map<String, dynamic>>>{};
      for (var transaction in recentTransactions) {
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
      for (var transaction in recentTransactions) {
        final payout = transaction['payout'] as double? ?? 
                      transaction['amount'] as double? ?? 0.0;
        weeklyEarnings += payout;
      }

      // Calculate weekly distance from recent KWH history
      for (var record in recentKwhHistory) {
        final distance = record['totalDistanceKm'] as double? ?? 0.0;
        weeklyDistance += distance;
      }
    }

    // Calculate average per session
    final avgEarningsPerSession = totalSessions > 0 ? totalEarnings / totalSessions : 0.0;
    final avgEnergyPerSession = totalSessions > 0 ? totalEnergy / totalSessions : 0.0;
    final avgDistancePerSession = totalSessions > 0 ? totalDistance / totalSessions : 0.0;
    
    // Calculate weekly average (divide by number of weeks)
    final weeklyAvgEarnings = recentWeeks > 0 ? weeklyEarnings / recentWeeks : 0.0;
    final weeklyAvgDistance = recentWeeks > 0 ? weeklyDistance / recentWeeks : 0.0;

    setState(() {
      _totalSessions = totalSessions;
      _daysWithActivity = daysWithActivity;
      _averageEarningsPerSession = avgEarningsPerSession;
      _averageEnergyPerSession = avgEnergyPerSession;
      _averageDistancePerSession = avgDistancePerSession;
      _weeklyAverageEarnings = weeklyAvgEarnings;
      _weeklyAverageDistance = weeklyAvgDistance;
      
      // Set initial sessions per week based on activity
      if (daysWithActivity > 0) {
        _sessionsPerWeek = (daysWithActivity / 7).ceil().clamp(1, 7);
      }
    });
  }

  void _calculateProjections() {
    // Calculate monthly projection based on sessions per week
    final weeksPerMonth = 4.33; // Average weeks per month
    final sessionsPerMonth = _sessionsPerWeek * weeksPerMonth;
    
    final projectedEarnings = _averageEarningsPerSession * sessionsPerMonth;
    final projectedEnergy = _averageEnergyPerSession * sessionsPerMonth;
    final projectedDistance = _averageDistancePerSession * sessionsPerMonth;
    
    // Current monthly projection (based on weekly average)
    final currentMonthlyEarnings = _weeklyAverageEarnings * weeksPerMonth;

    setState(() {
      _projectedMonthlyEarnings = projectedEarnings;
      _projectedMonthlyEnergy = projectedEnergy;
      _projectedMonthlyDistance = projectedDistance;
      _currentMonthlyProjection = currentMonthlyEarnings;
    });
  }

  // Calculate analytics data based on selected filter
  List<Map<String, dynamic>> _getAnalyticsData() {
    if (_recentTransactions.isEmpty) return [];

    final aggregated = <DateTime, double>{};
    
    // Determine limit based on filter (outside the loop)
    int limit;
    switch (_analyticsFilter) {
      case 'weekly':
        limit = 4; // Last 4 weeks
        break;
      case 'monthly':
        limit = 6; // Last 6 months
        break;
      case 'all time':
        limit = 999; // All available data
        break;
      default:
        limit = 4;
    }

    for (final transaction in _recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ?? 
                       transaction['timeStamp'] as DateTime?;
      if (timestamp == null) continue;
      
      final amount = transaction['payout'] as double? ?? 
                     transaction['amount'] as double? ?? 0.0;

      DateTime key;
      
      switch (_analyticsFilter) {
        case 'weekly':
          final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case 'monthly':
          key = DateTime(timestamp.year, timestamp.month);
          break;
        case 'all time':
          key = DateTime(timestamp.year, timestamp.month);
          break;
        default:
          final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
          key = DateTime(weekStart.year, weekStart.month, weekStart.day);
      }

      aggregated[key] = (aggregated[key] ?? 0.0) + amount;
    }

    // Helper function for full month names
    String fullMonthName(int m) {
      const names = [
        '', 'January', 'February', 'March', 'April', 'May', 'June', 
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return names[m];
    }

    // Convert to list and format
    final entries = aggregated.entries.map((e) {
      final DateTime dt = e.key;
      String label;

      switch (_analyticsFilter) {
        case 'weekly':
          // Will be updated after sorting to show Week 1, Week 2, etc.
          label = ''; // Placeholder, will be set after sorting
          break;
        case 'monthly':
          // Show full month name (e.g., "January", "February")
          label = fullMonthName(dt.month);
          break;
        case 'all time':
          // Show full month name (e.g., "January", "February")
          label = fullMonthName(dt.month);
          break;
        default:
          label = '';
      }

      return {
        'label': label,
        'amount': e.value,
        'date': dt,
      };
    }).toList();

    // Sort by date ascending (oldest first for chart)
    entries.sort((a, b) => 
      (a['date'] as DateTime).compareTo(b['date'] as DateTime)
    );

    // Limit to recent periods
    List<Map<String, dynamic>> limitedEntries;
    if (_analyticsFilter != 'all time' && entries.length > limit) {
      limitedEntries = entries.sublist(entries.length - limit);
    } else {
      limitedEntries = entries;
    }

    // For weekly filter, update labels to show Week 1, Week 2, etc.
    if (_analyticsFilter == 'weekly' && limitedEntries.isNotEmpty) {
      for (int i = 0; i < limitedEntries.length; i++) {
        limitedEntries[i]['label'] = 'Week ${i + 1}';
      }
    }

    return limitedEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      // floatingActionButton: const ChatFAB(), // Hidden for now
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPredictionData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const ScreenTitle(title: 'Earnings Prediction'),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Activity Summary
                          _buildCurrentActivityCard(),
                          const SizedBox(height: 16),
                          
                          // Frequency Selector
                          _buildFrequencySelector(),
                          const SizedBox(height: 16),
                          
                          // Monthly Projection Card
                          _buildProjectionCard(),
                          const SizedBox(height: 16),
                          
                          // Comparison Chart
                          _buildComparisonChart(),
                          const SizedBox(height: 16),
                          
                          // Tips and Motivation
                          _buildMotivationCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Your Activity Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '$_totalSessions',
                    Icons.directions_bike,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Days',
                    '$_daysWithActivity',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItemWithPeso(
                    'Avg/Session',
                    '₱${_averageEarningsPerSession.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (_weeklyAverageEarnings > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Average:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '₱${_weeklyAverageEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
              if (_weeklyAverageDistance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly Distance:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${_weeklyAverageDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF317263),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF317263), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItemWithPeso(String label, String value) {
    return Column(
      children: [
        Text(
          '₱',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF317263),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Adjust Your Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sessions per week: $_sessionsPerWeek',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _sessionsPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_sessionsPerWeek sessions/week',
              activeColor: const Color(0xFF317263),
              onChanged: (value) {
                setState(() {
                  _sessionsPerWeek = value.round();
                });
                _calculateProjections();
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1x/week',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Daily',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard() {
    final increase = _projectedMonthlyEarnings - _currentMonthlyProjection;
    final increasePercent = _currentMonthlyProjection > 0
        ? (increase / _currentMonthlyProjection * 100)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF317263),
              const Color(0xFF317263).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Earnings Projection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projected',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₱${_projectedMonthlyEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (increase > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${increasePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Based on current activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₱${_currentMonthlyProjection.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Energy Generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${(_projectedMonthlyEnergy / 1000).toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_projectedMonthlyDistance > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${_projectedMonthlyDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    final analyticsData = _getAnalyticsData();
    final maxValue = analyticsData.isEmpty 
        ? 1.0 
        : analyticsData.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);
    final chartHeight = 180.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Earnings Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: ['weekly', 'monthly', 'all time'].map((filter) {
                final selected = _analyticsFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      filter == 'all time' ? 'All Time' : (filter[0].toUpperCase() + filter.substring(1)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _analyticsFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF317263),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Line graph
            if (analyticsData.isEmpty)
              Container(
                height: chartHeight,
                alignment: Alignment.center,
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              SizedBox(
                height: chartHeight,
                child: Stack(
                  children: [
                    // Line chart background
                    CustomPaint(
                      size: Size.infinite,
                      painter: LineChartPainter(
                        data: analyticsData.map((e) => e['amount'] as double).toList(),
                        maxValue: maxValue,
                        color: const Color(0xFF317263),
                      ),
                    ),
                    // Labels overlay
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: analyticsData.asMap().entries.map((entry) {
                          final item = entry.value;
                          final amount = item['amount'] as double;
                          final label = item['label'] as String;
                          
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Value on top
                                Text(
                                  '₱${amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Label at bottom
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    final increase = _projectedMonthlyEarnings - _currentMonthlyProjection;
    String motivationText = '';
    String tipText = '';

    if (increase > 0) {
      motivationText = 'By increasing to $_sessionsPerWeek sessions per week, you could earn an additional ₱${increase.toStringAsFixed(2)} per month!';
      tipText = '💡 Tip: Consistency is key! Even small increases in frequency can lead to significant earnings over time.';
    } else if (_totalSessions == 0) {
      motivationText = 'Start your first session to begin earning! Every ride counts towards your monthly projection.';
      tipText = '💡 Tip: Begin with 1-2 sessions per week and gradually increase as you build your routine.';
    } else {
      motivationText = 'Keep up the great work! Maintain your current activity level to reach your monthly goal.';
      tipText = '💡 Tip: Try to maintain a consistent schedule. Regular biking sessions help build momentum!';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Motivation & Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              motivationText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                tipText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    
    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final numGridLines = 4;
    for (int i = 0; i <= numGridLines; i++) {
      final y = padding + (chartHeight / numGridLines) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + chartWidth, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines at data points
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0;
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + chartHeight),
        gridPaint,
      );
    }

    // Line paint for the data line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Point paint
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final y = padding + chartHeight - ((data[i] / maxValue) * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw the data line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.maxValue != maxValue || 
           oldDelegate.color != color;
  }
}
