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
                                  padding: EdgeInsets.fromLTRB(
                                    (MediaQuery.sizeOf(context).width * 0.04).clamp(12.0, 20.0),
                                    AppDimensions.paddingLarge,
                                    (MediaQuery.sizeOf(context).width * 0.04).clamp(12.0, 20.0),
                                    (MediaQuery.sizeOf(context).width * 0.08).clamp(24.0, 40.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildBoltCheckBanner(context),
                                      if (_insightsRepo.needsBoltCheck) const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildFinancialRealityCard(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildCurrentActivityCard(context),
                                      const SizedBox(height: AppDimensions.paddingLarge),
                                      _buildBikeHealthCard(context),
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

  EdgeInsets _cardPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = (w * 0.045).clamp(12.0, 24.0);
    return EdgeInsets.all(pad);
  }

  double _cardRadius(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return (w / 22).clamp(12.0, 20.0);
  }

  double _responsiveIconSize(BuildContext context) {
    final s = _fontScale(context);
    return 16 * s;
  }

  Widget _buildBoltCheckBanner(BuildContext context) {
    if (!_insightsRepo.needsBoltCheck) return const SizedBox.shrink();
    final km = _insightsRepo.kmSinceLastBoltCheck.toStringAsFixed(0);
    return _buildInfoBanner(
      context,
      icon: Icons.build_rounded,
      message: "Bolt check recommended — you've ridden ~$km km since last check. Tighten mounting bolts for safety.",
      backgroundColor: AppColors.warning.withValues(alpha: 0.25),
      iconColor: AppColors.warning,
      textColor: AppColors.darkText,
    );
  }

  Widget _buildFinancialRealityCard(BuildContext context) {
    const white = Colors.white;
    const white95 = Color(0xFFF2F2F2);
    final m = _insightsRepo;
    final s = _fontScale(context);
    final hasNoData = m.totalSessions == 0;

    final radius = _cardRadius(context);
    final padding = _cardPadding(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: _responsiveIconSize(context), color: white.withValues(alpha: 0.95)),
                const SizedBox(width: 6),
                Text(
                  'YOUR FINANCIAL REALITY',
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    color: white.withValues(alpha: 0.95),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            if (hasNoData) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildInfoBanner(
                context,
                icon: Icons.info_outline_rounded,
                message: 'Complete your first session to see your financial reality.',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ] else ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                formatCompactCurrency(m.netEarnings),
                style: TextStyle(
                  fontSize: 32 * s,
                  fontWeight: FontWeight.w700,
                  color: white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Real spendable earnings',
                style: TextStyle(fontSize: 14 * s, color: white95),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gross earned', style: TextStyle(fontSize: 12 * s, color: white95)),
                      Text(formatCompactCurrency(m.totalEarnings), style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w600, color: white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Repair jar', style: TextStyle(fontSize: 12 * s, color: white95)),
                      Text(formatCompactCurrency(m.maintenanceReserve), style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w600, color: white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              if (m.roiProgressPercent >= 100) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration_rounded, color: white, size: 20),
                      const SizedBox(width: 8),
                      Text('Investment recovered!', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: white)),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Breakeven Progress', style: TextStyle(fontSize: 12 * s, color: white95)),
                    Text('${m.roiProgressPercent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12 * s, fontWeight: FontWeight.w600, color: white)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (m.roiProgressPercent / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.homeAccent),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatCompactCurrency(m.remainingCapexDebt)} left to recover your ₱3,792 investment',
                  style: TextStyle(fontSize: 12 * s, color: white95),
                ),
              ],
              if (m.hourlyWage > 0) ...[
                const SizedBox(height: AppDimensions.paddingMedium),
                Row(
                  children: [
                    Text('${formatCompactCurrency(m.hourlyWage)}/hr ', style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: m.hourlyWage >= 30
                            ? AppColors.success.withValues(alpha: 0.3)
                            : m.hourlyWage >= 15
                                ? AppColors.warning.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.getEfficiencyStatus(),
                        style: TextStyle(
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w600,
                          color: white,
                        ),
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

  Widget _buildBikeHealthCard(BuildContext context) {
    final m = _insightsRepo;
    final s = _fontScale(context);
    final progress = (m.motorHealthPercent / 100).clamp(0.0, 1.0);
    Color ringColor = AppColors.success;
    if (m.motorHealthPercent <= 30) {
      ringColor = AppColors.error;
    } else if (m.motorHealthPercent <= 75) {
      ringColor = AppColors.warning;
    }
    final nextBoltKm = (100 - m.kmSinceLastBoltCheck).clamp(0.0, 100.0);
    final ringSize = (MediaQuery.sizeOf(context).width * 0.22).clamp(64.0, 96.0);
    final radius = _cardRadius(context);
    final padding = _cardPadding(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_rounded, size: _responsiveIconSize(context), color: AppColors.homePrimary),
                const SizedBox(width: 6),
                Text(
                  'BIKE HEALTH',
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.homePrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: ringSize,
                        height: ringSize,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: (ringSize / 10).clamp(6.0, 10.0),
                          backgroundColor: AppColors.textTertiary.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                        ),
                      ),
                      Text(
                        '${m.motorHealthPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: (ringSize * 0.22).clamp(14.0, 22.0),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: padding.horizontal / 2 + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.getMotorHealthStatus(),
                        style: TextStyle(
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      _buildBreakdownRow(
                        context,
                        'Distance',
                        m.totalDistanceKm >= 1000
                            ? '${formatCompactNumber(m.totalDistanceKm, 1)} km'
                            : '${m.totalDistanceKm.toStringAsFixed(1)} km',
                        AppColors.textSecondary,
                        AppColors.textPrimary,
                      ),
                      _buildBreakdownRow(
                        context,
                        'Energy',
                        formatEnergy(m.totalEnergyWh),
                        AppColors.textSecondary,
                        AppColors.textPrimary,
                      ),
                      _buildBreakdownRow(
                        context,
                        'Next bolt check',
                        '${nextBoltKm.toStringAsFixed(0)} km',
                        AppColors.textSecondary,
                        AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentActivityCard(BuildContext context) {
    const white = Colors.white;
    const white95 = Color(0xFFF2F2F2);
    final s = _fontScale(context);
    final radius = _cardRadius(context);
    final padding = _cardPadding(context);
    final m = _insightsRepo;
    final hasData = m.totalSessions > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVITY',
              style: TextStyle(
                fontSize: 12 * s,
                fontWeight: FontWeight.w600,
                color: white.withValues(alpha: 0.95),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Sessions',
                    '${m.totalSessions}',
                    Icons.directions_bike_rounded,
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: white.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Active days',
                    '${m.daysWithActivity}',
                    Icons.calendar_today_rounded,
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: white.withValues(alpha: 0.35),
                ),
                Expanded(
                  child: _buildStatItemWithPeso(
                    context,
                    'Avg/session',
                    formatCompactCurrency(m.averageEarningsPerSession),
                    iconColor: white,
                    valueColor: white,
                    labelColor: white95,
                  ),
                ),
              ],
            ),
            if (!hasData) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildInfoBanner(
                context,
                icon: Icons.info_outline_rounded,
                message: 'Complete a session to start tracking.',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ] else if (m.weeklyAverageEarnings > 0) ...[
              const SizedBox(height: AppDimensions.paddingSmall),
              Divider(color: white.withValues(alpha: 0.4), height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly avg', style: TextStyle(fontSize: 14 * s, color: white95)),
                  Text(
                    formatCompactCurrency(m.weeklyAverageEarnings),
                    style: TextStyle(fontSize: 16 * s, fontWeight: FontWeight.w600, color: white),
                  ),
                ],
              ),
            ],
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 15 * s, color: labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 15 * s, fontWeight: FontWeight.w600, color: valueColor),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(BuildContext context) {
    final data = _insightsRepo.getAnalyticsData();
    final hasData = data.any((e) => ((e['amount'] as num?)?.toDouble() ?? 0.0) > 0);
    final s = _fontScale(context);
    final radius = _cardRadius(context);
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.22).clamp(160.0, 220.0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: _cardPadding(context),
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
                height: chartHeight,
                child: Center(
                  child: Text(
                    'No earnings data for this period.',
                    style: TextStyle(fontSize: 15 * s, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: chartHeight,
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

  Widget _buildInfoBanner(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    final s = _fontScale(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.sizeOf(context).width * 0.03).clamp(12.0, 20.0),
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
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
                  fontSize: (13 * s).clamp(12.0, 15.0),
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
    final iconSize = (MediaQuery.sizeOf(context).width * 0.11).clamp(36.0, 44.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.homePrimary).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(iconSize / 4),
          ),
          child: Icon(icon, color: iconC, size: iconSize * 0.55),
        ),
        SizedBox(height: iconSize * 0.25),
        Text(
          value,
          style: TextStyle(
            fontSize: (20 * s).clamp(16.0, 24.0),
            fontWeight: FontWeight.w700,
            color: valueC,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: (12 * s).clamp(11.0, 14.0), color: labelC, fontWeight: FontWeight.w500, height: 1.2),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    final iconSize = (MediaQuery.sizeOf(context).width * 0.11).clamp(36.0, 44.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: iconC.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(iconSize / 4),
          ),
          child: Icon(Icons.paid_rounded, color: iconC, size: iconSize * 0.55),
        ),
        SizedBox(height: iconSize * 0.25),
        Text(
          value,
          style: TextStyle(
            fontSize: (16 * s).clamp(14.0, 20.0),
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
          style: TextStyle(fontSize: (12 * s).clamp(11.0, 14.0), color: labelC, fontWeight: FontWeight.w500, height: 1.2),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }


  Widget _buildProjectionCard(BuildContext context) {
    final hasNoData = _insightsRepo.totalSessions == 0;
    final s = _fontScale(context);
    final radius = _cardRadius(context);
    const white = Colors.white;
    const white85 = Color(0xFFD9D9D9);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: _cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: _responsiveIconSize(context), color: white.withValues(alpha: 0.95)),
                const SizedBox(width: 6),
                Text(
                  'MONTHLY PROJECTION',
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    color: white.withValues(alpha: 0.95),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            if (hasNoData) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              _buildInfoBanner(
                context,
                icon: Icons.info_outline_rounded,
                message: 'Complete a session to see your projected monthly earnings.',
                backgroundColor: white.withValues(alpha: 0.15),
                iconColor: white,
                textColor: white,
              ),
            ] else ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                formatCompactCurrency(_insightsRepo.projectedMonthlyEarnings),
                style: TextStyle(
                  fontSize: (28 * s).clamp(22.0, 34.0),
                  fontWeight: FontWeight.w700,
                  color: white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'At optimal (22 days): ${formatCompactCurrency(_insightsRepo.cbaReferenceMonthlyGross)} gross.',
                style: TextStyle(fontSize: 12 * s, color: white85, fontWeight: FontWeight.w400),
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
    final avgPerSession = _insightsRepo.averageEarningsPerSession;
    final projectedWeekly = avgPerSession > 0 ? avgPerSession * 7 : 0.0;
    final projectedMonthly = avgPerSession > 0 ? avgPerSession * 30 : 0.0;
    final projectedYearly = avgPerSession > 0 ? avgPerSession * 365 : 0.0;
    final projectedAllTime = avgPerSession > 0 ? allTimeEarnings + (avgPerSession * 365) : allTimeEarnings;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_cardRadius(context)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.25), width: 1),
      ),
      child: Padding(
        padding: _cardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BATTERY UNITS',
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.homePrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
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
      final emptyHeight = (MediaQuery.sizeOf(context).height * 0.22).clamp(160.0, 220.0);
      return Container(
        height: emptyHeight,
        alignment: Alignment.center,
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
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
    final breakevenTip = _insightsRepo.cbaBreakevenMessage;
    final m = _insightsRepo;
    final s = _fontScale(context);
    String tipText = breakevenTip;

    if (m.totalSessions == 0) {
      tipText = 'Complete a session to start earning and see your stats.';
    } else if (m.needsBoltCheck) {
      tipText = 'Bolt check due soon (~100 km). Tighten mounting bolts for safety.';
    } else if (m.motorHealthPercent <= 30) {
      tipText = 'Motor brush life low. Consider a check or replacement.';
    } else if (m.roiProgressPercent > 0 && m.roiProgressPercent < 100) {
      tipText = '${m.roiProgressPercent.toStringAsFixed(0)}% to breakeven. $breakevenTip';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_cardRadius(context)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.25), width: 1),
      ),
      child: Padding(
        padding: _cardPadding(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: _responsiveIconSize(context), color: AppColors.homePrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tipText,
                style: TextStyle(
                  fontSize: (14 * s).clamp(13.0, 16.0),
                  height: 1.45,
                  color: AppColors.textPrimary,
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

