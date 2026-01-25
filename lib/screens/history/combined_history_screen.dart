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
    return Scaffold(
      appBar: const Header(),
      // floatingActionButton: const ChatFAB(), // Hidden for now
      body: Column(
        children: [
          // Folder-like TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 18,
                        color: _tabController.index == 0 
                            ? Colors.white 
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      const Text('Energy History'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 18,
                        color: _tabController.index == 1 
                            ? Colors.white 
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      const Text('Transaction History'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
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
                const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Total Generated',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  formatEnergy(_totalGenerated),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_bike, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Total Distance',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${_totalDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTopCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
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
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'TOTAL Redeemed',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '₱ ${_totalRedeemed.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.battery_charging_full, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Batteries Exchanged',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '$_batteryExchangeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKwhFilterChips() {
    const choices = ['daily', 'weekly', 'monthly', 'yearly'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.032).clamp(10.0, 14.0); // Responsive font size
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
    final fontSize = (screenWidth * 0.032).clamp(10.0, 14.0); // Responsive font size
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
        child: Text(
          'No energy data for $_kwhFilter',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatEnergy((item['value'] as num?)?.toDouble() ?? 0.0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                      ],
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
        child: Text(
          'No transactions for $_transactionFilter',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₱ ${((item['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                      ],
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
