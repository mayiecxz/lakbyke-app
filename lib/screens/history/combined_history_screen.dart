import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/services/kwh_service.dart';
import 'package:lakbyke_mobile/services/transaction_service.dart';

class CombinedHistoryScreen extends StatefulWidget {
  const CombinedHistoryScreen({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
    _loadKwhData();
    _loadTransactionData();
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
          const ScreenTitle(title: 'History'),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.homePrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.homePrimary,
            tabs: const [
              Tab(text: 'Energy History'),
              Tab(text: 'Transaction History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _kwhFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(c[0].toUpperCase() + c.substring(1)),
              selected: selected,
              onSelected: (_) {
                setState(() => _kwhFilter = c);
                _loadKwhData();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDim,
              labelStyle: TextStyle(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _transactionFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(c[0].toUpperCase() + c.substring(1)),
              selected: selected,
              onSelected: (_) {
                setState(() => _transactionFilter = c);
                _loadTransactionData();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceDim,
              labelStyle: TextStyle(
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatEnergy((item['energy'] as num?)?.toDouble() ?? 0.0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₱ ${((item['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
