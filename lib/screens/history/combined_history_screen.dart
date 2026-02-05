import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/services/kwh_service.dart';
import 'package:lakbyke_mobile/services/transaction_service.dart';
import 'package:lakbyke_mobile/widgets/energy_detail_modal.dart';
import 'package:lakbyke_mobile/widgets/transaction_detail_modal.dart';

class CombinedHistoryScreen extends StatefulWidget {
  const CombinedHistoryScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<CombinedHistoryScreen> createState() => _CombinedHistoryScreenState();
}

class _CombinedHistoryScreenState extends State<CombinedHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KwhService _kwhService = KwhService();
  final TransactionService _transactionService = TransactionService();
  
  // KWH History state
  String _kwhFilter = 'daily';
  List<Map<String, dynamic>> _kwhData = [];
  double _totalGenerated = 0.0;
  double _totalDistance = 0.0;
  bool _kwhLoading = true;
  
  // Transaction History state
  String _transactionFilter = 'daily';
  List<Map<String, dynamic>> _transactionData = [];
  double _totalRedeemed = 0.0;
  int _batteryExchangeCount = 0;
  bool _transactionLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes for icon color updates
    });
    _loadKwhData();
    _loadTransactionData();
  }

  @override
  void didUpdateWidget(CombinedHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update tab controller if initialTabIndex changed
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKwhData() async {
    setState(() => _kwhLoading = true);
    try {
      final results = await Future.wait([
        _kwhService.getAggregatedData(_kwhFilter),
        _kwhService.getTotalKwhGenerated(),
        _kwhService.getTotalDistanceKm(),
      ]);
      setState(() {
        _kwhData = results[0] as List<Map<String, dynamic>>? ?? [];
        _totalGenerated = (results[1] as num?)?.toDouble() ?? 0.0;
        _totalDistance = (results[2] as num?)?.toDouble() ?? 0.0;
        _kwhLoading = false;
      });
    } catch (e) {
      setState(() => _kwhLoading = false);
    }
  }

  Future<void> _loadTransactionData() async {
    setState(() => _transactionLoading = true);
    try {
      final results = await Future.wait([
        _transactionService.getAggregatedData(_transactionFilter),
        _transactionService.getTotalRedeemed(),
        _transactionService.getBatteryExchangeCount(),
      ]);
      setState(() {
        _transactionData = results[0] as List<Map<String, dynamic>>? ?? [];
        _totalRedeemed = (results[1] as num?)?.toDouble() ?? 0.0;
        _batteryExchangeCount = (results[2] as num?)?.toInt() ?? 0;
        _transactionLoading = false;
      });
    } catch (e) {
      setState(() => _transactionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tabMarginH = (w * 0.04).clamp(8.0, 16.0);
    final tabFontSize = (w * 0.032).clamp(11.0, 14.0);
    final tabIconSize = (w * 0.045).clamp(14.0, 18.0);
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
                  child: Column(
                    children: [
                      // Folder-like TabBar
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: tabMarginH, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[700],
                          indicator: BoxDecoration(
                            color: AppColors.homePrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: TextStyle(
                            fontSize: tabFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: tabFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt,
                                    size: tabIconSize,
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                  SizedBox(width: (w * 0.012).clamp(4.0, 6.0)),
                                  Text('Energy History', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    size: tabIconSize,
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                  SizedBox(width: (w * 0.012).clamp(4.0, 6.0)),
                                  Text('Transaction History', overflow: TextOverflow.ellipsis, maxLines: 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildKwhHistoryTab(),
                            _buildTransactionHistoryTab(),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildKwhHistoryTab() {
    return Column(
      children: [
        _buildKwhTopCard(),
        const SizedBox(height: 8),
        _buildKwhFilterChips(),
        const SizedBox(height: 12),
        Expanded(child: _buildKwhHistoryList()),
      ],
    );
  }

  Widget _buildTransactionHistoryTab() {
    return Column(
      children: [
        _buildTransactionTopCard(),
        const SizedBox(height: 8),
        _buildTransactionFilterChips(),
        const SizedBox(height: 12),
        Expanded(child: _buildTransactionHistoryList()),
      ],
    );
  }

  Widget _buildKwhTopCard() {
    final hasNoData = !_kwhLoading && _totalGenerated == 0.0 && _totalDistance == 0.0;
    final w = MediaQuery.of(context).size.width;
    final hPad = (w * 0.05).clamp(8.0, 20.0);
    final cardPad = (w * 0.045).clamp(12.0, 18.0);
    final iconMain = (w * 0.07).clamp(20.0, 28.0);
    final iconSec = (w * 0.06).clamp(18.0, 24.0);
    final fontSizeMain = (w * 0.07).clamp(18.0, 28.0);
    final fontSizeSec = (w * 0.06).clamp(16.0, 24.0);
    final labelFontSize = (w * 0.032).clamp(11.0, 14.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: AppColors.homeAccent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: iconMain),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'Total Generated',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: labelFontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _kwhLoading ? '...' : (_totalGenerated >= 1000000 ? '${formatCompactNumber(_totalGenerated / 1000)} kWh' : formatEnergy(_totalGenerated)),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: (w * 0.02).clamp(8.0, 12.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bike, color: Colors.white, size: iconSec),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'Total Distance',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: labelFontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _kwhLoading ? '...' : '${_totalDistance.abs() >= 1000 ? formatCompactNumber(_totalDistance, 1) : _totalDistance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeSec,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasNoData) ...[
              const SizedBox(height: 12),
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
                        'No energy data recorded yet. Start biking to generate energy!',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTopCard() {
    final hasNoData = !_transactionLoading && _totalRedeemed == 0.0 && _batteryExchangeCount == 0;
    final w = MediaQuery.of(context).size.width;
    final hPad = (w * 0.05).clamp(8.0, 20.0);
    final cardPad = (w * 0.045).clamp(12.0, 18.0);
    final iconMain = (w * 0.07).clamp(20.0, 28.0);
    final iconSec = (w * 0.06).clamp(18.0, 24.0);
    final fontSizeMain = (w * 0.07).clamp(18.0, 28.0);
    final fontSizeSec = (w * 0.06).clamp(16.0, 24.0);
    final labelFontSize = (w * 0.032).clamp(11.0, 14.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: AppColors.homeAccent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white, size: iconMain),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'TOTAL Redeemed',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: labelFontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _transactionLoading ? '...' : formatCompactCurrency(_totalRedeemed),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: (w * 0.02).clamp(8.0, 12.0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_charging_full, color: Colors.white, size: iconSec),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'Batteries Exchanged',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: labelFontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _transactionLoading ? '...' : (_batteryExchangeCount >= 1000 ? formatCompactNumber(_batteryExchangeCount, 0) : '$_batteryExchangeCount'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeSec,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasNoData) ...[
              const SizedBox(height: 12),
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
                        'No transactions recorded yet. Redeem your energy to see transaction history!',
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
          ],
        ),
      ),
    );
  }

  Widget _buildKwhFilterChips() {
    const choices = ['daily', 'weekly', 'monthly', 'yearly'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.032).clamp(10.0, 14.0);
    final hPad = (screenWidth * 0.05).clamp(8.0, 20.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _kwhFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                c[0].toUpperCase() + c.substring(1),
                style: TextStyle(fontSize: fontSize),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() => _kwhFilter = c);
                _loadKwhData();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDim,
              labelStyle: TextStyle(
                fontSize: fontSize,
                color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionFilterChips() {
    const choices = ['daily', 'weekly', 'monthly', 'yearly'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.032).clamp(10.0, 14.0);
    final hPad = (screenWidth * 0.05).clamp(8.0, 20.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _transactionFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                c[0].toUpperCase() + c.substring(1),
                style: TextStyle(fontSize: fontSize),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() => _transactionFilter = c);
                _loadTransactionData();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDim,
              labelStyle: TextStyle(
                fontSize: fontSize,
                color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKwhHistoryList() {
    if (_kwhLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kwhData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bolt_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Energy Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _kwhFilter == 'daily'
                    ? 'No energy data available for the selected period. Start biking to generate energy!'
                    : 'No energy data for $_kwhFilter period. Your energy history will appear here once you start generating power.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final listPadH = (w * 0.04).clamp(8.0, 20.0);
    final rowPadH = (w * 0.04).clamp(12.0, 16.0);
    final rowPadV = (w * 0.03).clamp(10.0, 14.0);
    final chevronSize = (w * 0.05).clamp(16.0, 20.0);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: listPadH, vertical: 12.0),
      itemCount: _kwhData.length,
      itemBuilder: (context, index) {
        final item = _kwhData[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _kwhData.length - 1 ? 12 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEnergyDetailModal(context, item),
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: rowPadH, vertical: rowPadV),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: (w * 0.02).clamp(8.0, 12.0)),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _formatEnergyDisplay((item['value'] as num?)?.toDouble() ?? 0.0),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: (w * 0.02).clamp(6.0, 8.0)),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: chevronSize),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistoryList() {
    if (_transactionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactionData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _transactionFilter == 'daily'
                    ? 'No transactions available for the selected period. Complete a battery exchange to see your transaction history!'
                    : 'No transactions for $_transactionFilter period. Your transaction history will appear here once you redeem your energy.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final listPadH = (w * 0.04).clamp(8.0, 20.0);
    final rowPadH = (w * 0.04).clamp(12.0, 16.0);
    final rowPadV = (w * 0.03).clamp(10.0, 14.0);
    final chevronSize = (w * 0.05).clamp(16.0, 20.0);
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: listPadH, vertical: 12.0),
      itemCount: _transactionData.length,
      itemBuilder: (context, index) {
        final item = _transactionData[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _transactionData.length - 1 ? 12 : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTransactionDetailModal(context, item),
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: rowPadH, vertical: rowPadV),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: (w * 0.02).clamp(8.0, 12.0)),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              formatCompactCurrency((item['amount'] as num?)?.toDouble() ?? 0.0),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: (w * 0.02).clamp(6.0, 8.0)),
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: chevronSize),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatEnergyDisplay(double wh) {
    return wh >= 1000000 ? '${formatCompactNumber(wh / 1000)} kWh' : formatEnergy(wh);
  }

  Future<void> _showEnergyDetailModal(BuildContext context, Map<String, dynamic> item) async {
    try {
      final periodDate = item['date'] as DateTime?;
      if (periodDate == null) return;

      final energy = (item['value'] as num?)?.toDouble() ?? 0.0;
      final distance = (item['distance'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';

      // Fetch detailed records for this period
      final detailedRecords = await _kwhService.getDetailedRecordsForPeriod(
        periodDate: periodDate,
        filterType: _kwhFilter,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => EnergyDetailModal(
            periodLabel: label,
            periodDate: periodDate,
            filterType: _kwhFilter,
            totalEnergy: energy,
            totalDistance: distance,
            detailedRecords: detailedRecords,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTransactionDetailModal(BuildContext context, Map<String, dynamic> item) async {
    try {
      final periodDate = item['date'] as DateTime?;
      if (periodDate == null) return;

      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';

      // Fetch detailed transactions for this period
      final detailedTransactions = await _transactionService.getDetailedTransactionsForPeriod(
        periodDate: periodDate,
        filterType: _transactionFilter,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => TransactionDetailModal(
            periodLabel: label,
            periodDate: periodDate,
            filterType: _transactionFilter,
            totalAmount: amount,
            detailedTransactions: detailedTransactions,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
