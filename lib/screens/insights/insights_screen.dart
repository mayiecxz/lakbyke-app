import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/models/insights/insights_model.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsModel _insightsModel = InsightsModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsightsData();
  }

  Future<void> _loadInsightsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _insightsModel.loadInsightsData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      // floatingActionButton: const ChatFAB(), // Hidden for now
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsightsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Activity Summary
                          _buildCurrentActivityCard(),
                          const SizedBox(height: 16),
                          
                          // Monthly Projection Card
                          _buildProjectionCard(),
                          const SizedBox(height: 16),
                          
                          // Battery Pictograph Chart
                          _buildBatteryPictograph(),
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
                    '${_insightsModel.totalSessions}',
                    Icons.directions_bike,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Days',
                    '${_insightsModel.daysWithActivity}',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItemWithPeso(
                    'Avg/Session',
                    '₱${_insightsModel.averageEarningsPerSession.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (_insightsModel.weeklyAverageEarnings > 0) ...[
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
                    '₱${_insightsModel.weeklyAverageEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
              if (_insightsModel.weeklyAverageDistance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly Distance:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${_insightsModel.weeklyAverageDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF317263),
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (_insightsModel.totalSessions == 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No activity recorded yet. Complete a session to start tracking your earnings!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_insightsModel.hasActivityInPastWeek() && !_insightsModel.hasActivityInPastMonth()) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No activity in the past week or month. Start a new session to see recent earnings!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_insightsModel.hasActivityInPastWeek()) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No activity in the past week. Your weekly average will update once you complete a session.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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


  Widget _buildProjectionCard() {
    final increase = _insightsModel.projectedMonthlyEarnings - _insightsModel.currentMonthlyProjection;
    final increasePercent = _insightsModel.currentMonthlyProjection > 0
        ? (increase / _insightsModel.currentMonthlyProjection * 100)
        : 0.0;
    
    final hasNoData = _insightsModel.totalSessions == 0;

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
            if (hasNoData) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white.withOpacity(0.9), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your first session to see earnings projections based on your activity.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      '₱${_insightsModel.projectedMonthlyEarnings.toStringAsFixed(2)}',
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
                      '₱${_insightsModel.currentMonthlyProjection.toStringAsFixed(2)}',
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
                      '${(_insightsModel.projectedMonthlyEnergy / 1000).toStringAsFixed(1)} kWh',
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
            if (_insightsModel.projectedMonthlyDistance > 0) ...[
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
                        '${_insightsModel.projectedMonthlyDistance.toStringAsFixed(1)} km',
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

  // Calculate earnings for different periods
  double _calculateWeeklyEarnings() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    double total = 0.0;
    
    for (final transaction in _insightsModel.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneWeekAgo)) {
        final amount = transaction['payout'] as double? ??
            transaction['amount'] as double? ??
            0.0;
        total += amount;
      }
    }
    return total;
  }

  double _calculateMonthlyEarnings() {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    double total = 0.0;
    
    for (final transaction in _insightsModel.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneMonthAgo)) {
        final amount = transaction['payout'] as double? ??
            transaction['amount'] as double? ??
            0.0;
        total += amount;
      }
    }
    return total;
  }

  double _calculateYearlyEarnings() {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    double total = 0.0;
    
    for (final transaction in _insightsModel.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneYearAgo)) {
        final amount = transaction['payout'] as double? ??
            transaction['amount'] as double? ??
            0.0;
        total += amount;
      }
    }
    return total;
  }

  double _calculateAllTimeEarnings() {
    double total = 0.0;
    
    for (final transaction in _insightsModel.recentTransactions) {
      final amount = transaction['payout'] as double? ??
          transaction['amount'] as double? ??
          0.0;
      total += amount;
    }
    return total;
  }

  Widget _buildBatteryPictograph() {
    final weeklyEarnings = _calculateWeeklyEarnings();
    final monthlyEarnings = _calculateMonthlyEarnings();
    final yearlyEarnings = _calculateYearlyEarnings();
    final allTimeEarnings = _calculateAllTimeEarnings();
    
    // Calculate projected earnings if cycling consistently
    // Use average earnings per session to project potential earnings
    final avgPerSession = _insightsModel.averageEarningsPerSession;
    
    // Project based on current activity patterns
    // Weekly: if cycling daily (7 sessions)
    final projectedWeekly = avgPerSession > 0 ? avgPerSession * 7 : 0.0;
    
    // Monthly: if cycling daily for a month (30 sessions)
    final projectedMonthly = avgPerSession > 0 ? avgPerSession * 30 : 0.0;
    
    // Yearly: if cycling daily for a year (365 sessions)
    final projectedYearly = avgPerSession > 0 ? avgPerSession * 365 : 0.0;
    
    // All time: show current total + one year projection if cycling daily
    final projectedAllTime = avgPerSession > 0 
        ? allTimeEarnings + (avgPerSession * 365)
        : allTimeEarnings;

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
                Icon(Icons.battery_charging_full, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Energy Earnings Pictograph',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'How much you can earn if cycling',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                {'key': 'weekly', 'label': 'Week', 'filter': 'past week'},
                {'key': 'monthly', 'label': 'Month', 'filter': 'past month'},
                {'key': 'yearly', 'label': 'Year', 'filter': 'past year'},
                {'key': 'all time', 'label': 'All Time', 'filter': 'all time'},
              ].map((period) {
                final selected = _insightsModel.analyticsFilter == period['filter'];
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        period['label']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _insightsModel.analyticsFilter = period['filter'] as String;
                        });
                      },
                      selectedColor: const Color(0xFF317263),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Pictograph display
            _buildPictographSection(
              period: _insightsModel.analyticsFilter,
              weeklyEarnings: weeklyEarnings,
              monthlyEarnings: monthlyEarnings,
              yearlyEarnings: yearlyEarnings,
              allTimeEarnings: allTimeEarnings,
              projectedWeekly: projectedWeekly,
              projectedMonthly: projectedMonthly,
              projectedYearly: projectedYearly,
              projectedAllTime: projectedAllTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictographSection({
    required String period,
    required double weeklyEarnings,
    required double monthlyEarnings,
    required double yearlyEarnings,
    required double allTimeEarnings,
    required double projectedWeekly,
    required double projectedMonthly,
    required double projectedYearly,
    required double projectedAllTime,
  }) {
    double earnings;
    double projected;
    String periodLabel;
    
    switch (period) {
      case 'past week':
        earnings = weeklyEarnings;
        projected = projectedWeekly;
        periodLabel = 'Weekly';
        break;
      case 'past month':
        earnings = monthlyEarnings;
        projected = projectedMonthly;
        periodLabel = 'Monthly';
        break;
      case 'past year':
        earnings = yearlyEarnings;
        projected = projectedYearly;
        periodLabel = 'Yearly';
        break;
      case 'all time':
        earnings = allTimeEarnings;
        projected = projectedAllTime;
        periodLabel = 'All Time';
        break;
      default:
        earnings = weeklyEarnings;
        projected = projectedWeekly;
        periodLabel = 'Weekly';
    }

    // Use projected earnings for the pictograph (how much they can earn if cycling)
    final displayEarnings = projected > 0 ? projected : earnings;
    
    // Each battery represents ₱50
    const double batteryValue = 50.0;
    final numBatteries = (displayEarnings / batteryValue).ceil();
    final maxBatteriesToShow = 20; // Limit display to prevent overflow
    final batteriesToShow = numBatteries > maxBatteriesToShow ? maxBatteriesToShow : numBatteries;
    final hasMore = numBatteries > maxBatteriesToShow;

    if (displayEarnings == 0 && _insightsModel.totalSessions == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.battery_charging_full,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No earnings data yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start cycling to see your potential earnings!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Earnings summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF317263).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$periodLabel Earnings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${displayEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Batteries',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasMore ? '$maxBatteriesToShow+' : '$numBatteries',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Battery pictograph
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(batteriesToShow, (index) {
                return Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF317263),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF317263).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.battery_charging_full,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              }),
            ),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Text(
            '+ ${numBatteries - maxBatteriesToShow} more batteries (₱${((numBatteries - maxBatteriesToShow) * batteryValue).toStringAsFixed(2)})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Each battery = ₱${batteryValue.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }



  Widget _buildMotivationCard() {
    final monthlyEarnings = _calculateMonthlyEarnings();
    final yearlyEarnings = _calculateYearlyEarnings();
    String motivationText = '';
    String tipText = '';

    if (_insightsModel.totalSessions == 0) {
      motivationText = 'Start your first session to begin earning! Every ride counts towards your potential earnings.';
      tipText = '💡 Tip: Begin cycling regularly to see your earnings grow! Each session contributes to your total.';
    } else if (yearlyEarnings > 0) {
      final projectedYearly = _insightsModel.averageEarningsPerSession > 0 
          ? _insightsModel.averageEarningsPerSession * 365 
          : 0.0;
      motivationText = 'Great progress! If you cycle daily, you could earn ₱${projectedYearly.toStringAsFixed(2)} per year!';
      tipText = '💡 Tip: Consistency is key! Regular cycling sessions help maximize your earnings potential.';
    } else if (monthlyEarnings > 0) {
      motivationText = 'Keep up the great work! Your cycling activity is generating earnings.';
      tipText = '💡 Tip: Try to maintain a consistent schedule. Regular biking sessions help build momentum!';
    } else {
      motivationText = 'Keep cycling to see your earnings grow! Every session counts.';
      tipText = '💡 Tip: Regular cycling sessions will help you maximize your energy generation and earnings!';
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

