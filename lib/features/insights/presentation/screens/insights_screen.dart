import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/shared/widgets/header.dart';
import 'package:lakbyke_mobile/shared/widgets/screen_title.dart';
import 'package:lakbyke_mobile/features/insights/data/repositories/insights_repository.dart';
import 'package:lakbyke_mobile/features/insights/providers/insights_providers.dart';
import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/core/utils/dimensions.dart';
import 'package:lakbyke_mobile/core/utils/formatting.dart';
import 'package:lakbyke_mobile/shared/widgets/index.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late final InsightsRepository _insightsRepo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _insightsRepo = ref.read(insightsRepositoryProvider);
    _loadInsightsData();
  }

  Future<void> _loadInsightsData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _insightsRepo.loadInsightsData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full-screen dark background (for the sides)
            Container(color: Colors.black),
            // 2. Main content area (white)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: _isLoading
                      ? const AppLoadingOverlay(message: 'Loading your insights...')
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
                                      _buildCurrentActivityCard(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildPerformanceBreakdownCard(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildEarningsChart(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildProjectionCard(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildBatteryPictograph(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildMotivationCard(context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // 3. Fixed Header overlay
            const Header(),
          ],
        ),
      ),
    );
  }

  double _fontScale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return (w / 360).clamp(1.0, 1.35);
  }

  Widget _buildCurrentActivityCard(BuildContext context) {
    const white = Colors.white;
    const white95 = Color(0xFFF2F2F2);
    final s = _fontScale(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVITY SUMMARY',
              style: TextStyle(
                fontSize: 12 * s,
                fontWeight: FontWeight.w600,
                color: white.withValues(alpha: 0.95),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Sessions',
                    '${_insightsRepo.totalSessions}',
                    Icons.directions_bike_rounded,
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: white.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Active Days',
                    '${_insightsRepo.daysWithActivity}',
                    Icons.calendar_today_rounded,
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: white.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _buildStatItemWithPeso(
                    context,
                    'Avg/Session',
                    formatCompactCurrency(_insightsRepo.averageEarningsPerSession),
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
              ],
            ),
            if (_insightsRepo.weeklyAverageEarnings > 0) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: white.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Average:',
                    style: TextStyle(fontSize: 16 * s, color: white95),
                  ),
                  Text(
                    formatCompactCurrency(_insightsRepo.weeklyAverageEarnings),
                    style: TextStyle(
                      fontSize: 18 * s,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_insightsRepo.weeklyAverageDistance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Distance:',
                      style: TextStyle(fontSize: 16 * s, color: white95),
                    ),
                    Text(
                      '${_insightsRepo.weeklyAverageDistance.abs() >= 1000 ? formatCompactNumber(_insightsRepo.weeklyAverageDistance, 1) : _insightsRepo.weeklyAverageDistance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 18 * s,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (_insightsRepo.totalSessions == 0) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: white.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity recorded yet. Complete a session to start tracking your earnings!',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ] else if (!_insightsRepo.hasActivityInPastWeek() && !_insightsRepo.hasActivityInPastMonth()) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: white.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity in the past week or month. Start a new session to see recent earnings!',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ] else if (!_insightsRepo.hasActivityInPastWeek()) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Divider(color: white.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                message: 'No activity in the past week. Your weekly average will update once you complete a session.',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBreakdownCard(BuildContext context) {
    const white = Colors.white;
    const white95 = Color(0xFFF2F2F2);
    final m = _insightsRepo;
    final s = _fontScale(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERFORMANCE BREAKDOWN',
              style: TextStyle(
                fontSize: 12 * s,
                fontWeight: FontWeight.w600,
                color: white.withValues(alpha: 0.95),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildBreakdownRow(context, 'Total earned', formatCompactCurrency(m.totalEarnings), white95, white),
            _buildBreakdownRow(context, 'Total energy', formatEnergy(m.totalEnergyWh), white95, white),
            _buildBreakdownRow(context, 'Total distance', m.totalDistanceKm >= 1000 ? '${formatCompactNumber(m.totalDistanceKm, 1)} km' : '${m.totalDistanceKm.toStringAsFixed(1)} km', white95, white),
            _buildBreakdownRow(context, 'Sessions', '${m.totalSessions}', white95, white),
            _buildBreakdownRow(context, 'Active days', '${m.daysWithActivity}', white95, white),
            _buildBreakdownRow(context, 'Avg earnings/session', formatCompactCurrency(m.averageEarningsPerSession), white95, white),
            _buildBreakdownRow(context, 'Avg energy/session', formatEnergy(m.averageEnergyPerSession), white95, white),
            _buildBreakdownRow(context, 'Avg distance/session', m.averageDistancePerSession >= 1000 ? '${formatCompactNumber(m.averageDistancePerSession, 1)} km' : '${m.averageDistancePerSession.toStringAsFixed(1)} km', white95, white),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, String value, Color labelColor, Color valueColor) {
    final s = _fontScale(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15 * s, color: labelColor)),
          Text(value, style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(BuildContext context) {
    final data = _insightsRepo.getAnalyticsData();
    final hasData = data.any((e) => ((e['amount'] as num?)?.toDouble() ?? 0.0) > 0);
    final s = _fontScale(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EARNINGS OVER TIME',
              style: TextStyle(
                fontSize: 12 * s,
                fontWeight: FontWeight.w600,
                color: AppColors.homePrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildChartPeriodTabs(context),
            const SizedBox(height: AppDimensions.paddingMedium),
            if (data.isEmpty || !hasData)
              SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'No earnings data for this period.',
                    style: TextStyle(fontSize: 15 * s, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: _EarningsBarChart(data: data),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPeriodTabs(BuildContext context) {
    const filters = ['past week', 'past month', 'past year', 'all time'];
    const labels = {'past week': 'Week', 'past month': 'Month', 'past year': 'Year', 'all time': 'All'};
    final s = _fontScale(context);
    return Row(
      children: filters.map((filter) {
        final selected = _insightsRepo.analyticsFilter == filter;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _insightsRepo.analyticsFilter = filter;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.homeAccent.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    labels[filter]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14 * s,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.homePrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? iconColor,
    Color? valueColor,
    Color? labelColor,
  }) {
    final iconC = iconColor ?? AppColors.homePrimary;
    final valueC = valueColor ?? AppColors.textPrimary;
    final labelC = labelColor ?? AppColors.textSecondary;
    final s = _fontScale(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.homePrimary).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconC, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 21 * s,
            fontWeight: FontWeight.w700,
            color: valueC,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13 * s,
            color: labelC,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItemWithPeso(
    BuildContext context,
    String label,
    String value, {
    Color? iconColor,
    Color? valueColor,
    Color? labelColor,
  }) {
    final iconC = iconColor ?? AppColors.homePrimary;
    final valueC = valueColor ?? AppColors.homePrimary;
    final labelC = labelColor ?? AppColors.textSecondary;
    final s = _fontScale(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconC.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.paid_rounded, color: iconC, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 17 * s,
            fontWeight: FontWeight.w700,
            color: valueC,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13 * s,
            color: labelC,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildProjectionCard(BuildContext context) {
    final increase = _insightsRepo.projectedMonthlyEarnings - _insightsRepo.currentMonthlyProjection;
    final increasePercent = _insightsRepo.currentMonthlyProjection > 0
        ? (increase / _insightsRepo.currentMonthlyProjection * 100)
        : 0.0;
    
    final hasNoData = _insightsRepo.totalSessions == 0;
    final s = _fontScale(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 16, color: Colors.white.withValues(alpha: 0.95)),
                const SizedBox(width: 6),
                Text(
                  'MONTHLY EARNINGS PROJECTION',
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            if (hasNoData) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete your first session to see earnings projections based on your activity.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w400,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCompactCurrency(_insightsRepo.projectedMonthlyEarnings),
                  style: TextStyle(
                    fontSize: 30 * s,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (increase > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '+${increasePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15 * s,
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
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProjectionMetric(
                  context,
                  'Current activity',
                  formatCompactCurrency(_insightsRepo.currentMonthlyProjection),
                ),
                _buildProjectionMetric(
                  context,
                  'Energy',
                  '${(_insightsRepo.projectedMonthlyEnergy / 1000).abs() >= 1000 ? formatCompactNumber(_insightsRepo.projectedMonthlyEnergy / 1000, 1) : (_insightsRepo.projectedMonthlyEnergy / 1000).toStringAsFixed(1)} kWh',
                ),
                if (_insightsRepo.projectedMonthlyDistance > 0)
                  _buildProjectionMetric(
                    context,
                    'Distance',
                    '${_insightsRepo.projectedMonthlyDistance.abs() >= 1000 ? formatCompactNumber(_insightsRepo.projectedMonthlyDistance, 1) : _insightsRepo.projectedMonthlyDistance.toStringAsFixed(1)} km',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'At optimal rate (₱30/battery), ~22 school days/month ≈ ${formatCompactCurrency(_insightsRepo.cbaReferenceMonthlyGross)} gross.',
              style: TextStyle(
                fontSize: 12 * s,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionMetric(BuildContext context, String label, String value) {
    final s = _fontScale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * s,
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15 * s,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
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
    
    for (final transaction in _insightsRepo.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneWeekAgo)) {
        final amount = (transaction['payout'] as num?)?.toDouble() ??
            (transaction['amount'] as num?)?.toDouble() ??
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
    
    for (final transaction in _insightsRepo.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneMonthAgo)) {
        final amount = (transaction['payout'] as num?)?.toDouble() ??
            (transaction['amount'] as num?)?.toDouble() ??
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
    
    for (final transaction in _insightsRepo.recentTransactions) {
      final timestamp = transaction['timestamp'] as DateTime? ??
          transaction['timeStamp'] as DateTime?;
      if (timestamp != null && timestamp.isAfter(oneYearAgo)) {
        final amount = (transaction['payout'] as num?)?.toDouble() ??
            (transaction['amount'] as num?)?.toDouble() ??
            0.0;
        total += amount;
      }
    }
    return total;
  }

  double _calculateAllTimeEarnings() {
    double total = 0.0;
    
    for (final transaction in _insightsRepo.recentTransactions) {
      final amount = (transaction['payout'] as num?)?.toDouble() ??
          (transaction['amount'] as num?)?.toDouble() ??
          0.0;
      total += amount;
    }
    return total;
  }

  Widget _buildBatteryPictograph(BuildContext context) {
    final weeklyEarnings = _calculateWeeklyEarnings();
    final monthlyEarnings = _calculateMonthlyEarnings();
    final yearlyEarnings = _calculateYearlyEarnings();
    final allTimeEarnings = _calculateAllTimeEarnings();
    final s = _fontScale(context);
    
    // Calculate projected earnings if cycling consistently
    // Use average earnings per session to project potential earnings
    final avgPerSession = _insightsRepo.averageEarningsPerSession;
    
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.homePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ENERGY EARNINGS',
                    style: TextStyle(
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.homePrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Potential earnings if cycling regularly',
              style: TextStyle(
                fontSize: 14 * s,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Underline-style tabs
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
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
                  final selected = _insightsRepo.analyticsFilter == filter;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _insightsRepo.analyticsFilter = filter;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            labels[filter]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14 * s,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected
                                  ? AppColors.homePrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            // Pictograph display
            _buildPictographSection(
              context,
              period: _insightsRepo.analyticsFilter,
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

  Widget _buildPictographSection(
    BuildContext context, {
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
    final s = _fontScale(context);
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
    final double batteryValue = _insightsRepo.cbaBatteryValue; // CBA: 1 unit (72Wh) = ₱30
    final numBatteries = (displayEarnings / batteryValue).ceil();
    final maxBatteriesToShow = 20; // Limit display to prevent overflow
    final batteriesToShow = numBatteries > maxBatteriesToShow ? maxBatteriesToShow : numBatteries;
    final hasMore = numBatteries > maxBatteriesToShow;

    if (displayEarnings == 0 && _insightsRepo.totalSessions == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.homePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.battery_charging_full_rounded,
                size: 36,
                color: AppColors.homePrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No earnings data yet',
              style: TextStyle(
                fontSize: 17 * s,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete a session to see potential earnings.',
              style: TextStyle(
                fontSize: 14 * s,
                color: AppColors.textTertiary,
                height: 1.3,
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
            vertical: 14,
            horizontal: AppDimensions.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppColors.homePrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: AppColors.homePrimary.withValues(alpha: 0.15),
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
                    periodLabel,
                    style: TextStyle(
                      fontSize: 12 * s,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCompactCurrency(displayEarnings),
                    style: TextStyle(
                      fontSize: 20 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.homePrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Units',
                    style: TextStyle(
                      fontSize: 12 * s,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasMore ? '$maxBatteriesToShow+' : '$numBatteries',
                    style: TextStyle(
                      fontSize: 20 * s,
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
        // Battery pictograph — modern grid
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceDim.withValues(alpha: 0.5),
                AppColors.surfaceDim,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.homePrimary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(batteriesToShow, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _BatteryUnitTile(
                      index: index,
                      total: batteriesToShow,
                    ),
                  );
                }),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.homePrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.homePrimary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+${numBatteries - maxBatteriesToShow}',
                            style: TextStyle(
                              fontSize: 18 * s,
                              fontWeight: FontWeight.w700,
                              color: AppColors.homePrimary.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'more',
                            style: TextStyle(
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatCompactCurrency((numBatteries - maxBatteriesToShow) * batteryValue),
                            style: TextStyle(
                              fontSize: 13 * s,
                              fontWeight: FontWeight.w600,
                              color: AppColors.homePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.homePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    size: 14,
                    color: AppColors.homePrimary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '1 unit = ${formatCompactCurrency(batteryValue)}',
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildMotivationCard(BuildContext context) {
    final monthlyEarnings = _calculateMonthlyEarnings();
    final yearlyEarnings = _calculateYearlyEarnings();
    final netDaily = _insightsRepo.cbaNetDailyEarnings;
    final breakevenTip = _insightsRepo.cbaBreakevenMessage;
    final s = _fontScale(context);
    String motivationText = '';
    String tipText = '';

    if (_insightsRepo.totalSessions == 0) {
      motivationText = 'Start your first session to begin earning! Every ride counts towards your potential earnings.';
      tipText = '💡 Tip: Begin cycling regularly to see your earnings grow! Each session contributes to your total.';
    } else if (yearlyEarnings > 0) {
      motivationText = 'Great progress! At the optimal rate (₱30/battery), selling 1 full battery per day is about ₱30/day gross, ~${formatCompactCurrency(netDaily)}/day net after maintenance.';
      tipText = '💡 Tip: $breakevenTip';
    } else if (monthlyEarnings > 0) {
      motivationText = 'Keep up the great work! Your cycling activity is generating earnings.';
      tipText = '💡 Tip: $breakevenTip';
    } else {
      motivationText = 'Keep cycling to see your earnings grow! Every session counts.';
      tipText = '💡 Tip: $breakevenTip';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.homePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.homePrimary),
                      const SizedBox(width: 6),
                      Text(
                        'TIPS',
                        style: TextStyle(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.homePrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              motivationText,
              style: TextStyle(
                fontSize: 16 * s,
                height: 1.55,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.homeAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: AppColors.homePrimary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 20, color: AppColors.homePrimary.withValues(alpha: 0.9)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tipText.replaceFirst('💡 Tip: ', ''),
                      style: TextStyle(
                        fontSize: 15 * s,
                        color: AppColors.textPrimary.withValues(alpha: 0.9),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
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
}

/// A single battery unit tile for the energy earnings pictograph.
class _BatteryUnitTile extends StatelessWidget {
  final int index;
  final int total;

  const _BatteryUnitTile({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.homePrimary.withValues(alpha: 0.95),
            AppColors.homePrimary,
            AppColors.homePrimary.withValues(alpha: 0.88),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.homePrimary.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle top highlight
          Positioned(
            top: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Icon(
            Icons.battery_charging_full_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _EarningsBarChart extends StatelessWidget {
  const _EarningsBarChart({required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 100.0
        : (data.map<double>((e) => (e['amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);
    final barGroups = data.asMap().entries.map((entry) {
      final amount = (entry.value['amount'] as num).toDouble();
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: AppColors.homeAccent,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final amount = (data[group.x]['amount'] as num).toDouble();
              return BarTooltipItem(
                formatCompactCurrency(amount),
                TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final label = data[i]['label'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₱${value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.textTertiary.withValues(alpha: 0.2))),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
      duration: const Duration(milliseconds: 200),
    );
  }
}

