import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
import 'package:lakbyke_mobile/models/insights/insights_model.dart';
import 'package:lakbyke_mobile/utils/colors.dart';
import 'package:lakbyke_mobile/utils/dimensions.dart';

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
      backgroundColor: AppColors.background,
      appBar: const Header(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadInsightsData,
              color: AppColors.homePrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenTitle(title: 'INSIGHTS'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.paddingMedium,
                        AppDimensions.paddingLarge,
                        AppDimensions.paddingMedium,
                        AppDimensions.paddingXLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentActivityCard(),
                          const SizedBox(height: AppDimensions.paddingLarge),
                          _buildProjectionCard(),
                          const SizedBox(height: AppDimensions.paddingLarge),
                          _buildBatteryPictograph(),
                          const SizedBox(height: AppDimensions.paddingLarge),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.homePrimary),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Loading your insights...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVITY SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${_insightsModel.totalSessions}',
                    Icons.directions_bike_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Days',
                    '${_insightsModel.daysWithActivity}',
                    Icons.calendar_today_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
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
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: AppColors.textTertiary.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Average:',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  Text(
                    '₱${_insightsModel.weeklyAverageEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.homePrimary,
                    ),
                  ),
                ],
              ),
              if (_insightsModel.weeklyAverageDistance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Distance:',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${_insightsModel.weeklyAverageDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.homePrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (_insightsModel.totalSessions == 0) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: AppColors.textTertiary.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity recorded yet. Complete a session to start tracking your earnings!',
                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                iconColor: AppColors.warning,
                textColor: const Color(0xFFE65100),
              ),
            ] else if (!_insightsModel.hasActivityInPastWeek() && !_insightsModel.hasActivityInPastMonth()) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: AppColors.textTertiary.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity in the past week or month. Start a new session to see recent earnings!',
                backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                iconColor: AppColors.warning,
                textColor: const Color(0xFFE65100),
              ),
            ] else if (!_insightsModel.hasActivityInPastWeek()) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: AppColors.textTertiary.withValues(alpha: 0.5), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity in the past week. Your weekly average will update once you complete a session.',
                backgroundColor: AppColors.info.withValues(alpha: 0.12),
                iconColor: AppColors.info,
                textColor: const Color(0xFF1565C0),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required String message,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.homePrimary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
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
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.homePrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.homePrimary.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MONTHLY EARNINGS PROJECTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 1.4,
              ),
            ),
            if (hasNoData) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete your first session to see earnings projections based on your activity.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${_insightsModel.projectedMonthlyEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (increase > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${increasePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProjectionMetric(
                  'Current activity',
                  '₱${_insightsModel.currentMonthlyProjection.toStringAsFixed(2)}',
                ),
                _buildProjectionMetric(
                  'Energy',
                  '${(_insightsModel.projectedMonthlyEnergy / 1000).toStringAsFixed(1)} kWh',
                ),
                if (_insightsModel.projectedMonthlyDistance > 0)
                  _buildProjectionMetric(
                    'Distance',
                    '${_insightsModel.projectedMonthlyDistance.toStringAsFixed(1)} km',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENERGY EARNINGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Potential earnings if cycling regularly',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Underline-style tabs
            Row(
              children: [
                'past week',
                'past month',
                'past year',
                'all time',
              ].map((filter) {
                final labels = {
                  'past week': 'Week',
                  'past month': 'Month',
                  'past year': 'Year',
                  'all time': 'All',
                };
                final selected = _insightsModel.analyticsFilter == filter;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _insightsModel.analyticsFilter = filter;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            labels[filter]!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? AppColors.homePrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          color: selected ? AppColors.homePrimary : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
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
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.battery_charging_full_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No earnings data yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete a session to see potential earnings.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
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
        // Earnings summary — table-like row
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: AppDimensions.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$periodLabel',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${displayEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.homePrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMore ? '$maxBatteriesToShow+' : '$numBatteries',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.homePrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        // Battery pictograph — flat blocks
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
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
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.homePrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.battery_charging_full_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                );
              }),
            ),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Text(
            '+ ${numBatteries - maxBatteriesToShow} more (₱${((numBatteries - maxBatteriesToShow) * batteryValue).toStringAsFixed(2)})',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '1 unit = ₱${batteryValue.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.homePrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'TIPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              motivationText,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                tipText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D4037),
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

