import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'daily';
  int _currentPage = 1;

  // Realistic sample data spanning multiple weeks
  final List<Map<String, dynamic>> _allData = const [
    {'date': '12/06/25', 'type': 'Redemption', 'amount': 155},
    {'date': '12/05/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '12/04/25', 'type': 'Redemption', 'amount': 200},
    {'date': '12/03/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '12/02/25', 'type': 'Redemption', 'amount': 120},
    {'date': '12/01/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '11/30/25', 'type': 'Redemption', 'amount': 180},
    {'date': '11/29/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '11/28/25', 'type': 'Redemption', 'amount': 175},
    {'date': '11/27/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '11/26/25', 'type': 'Redemption', 'amount': 165},
    {'date': '11/25/25', 'type': 'Battery Exchange', 'amount': 50},
    {'date': '11/24/25', 'type': 'Redemption', 'amount': 190},
    {'date': '11/23/25', 'type': 'Battery Exchange', 'amount': 50},
  ];

  DateTime? _parseDate(String s) {
    try {
      final parts = s.split('/');
      if (parts.length != 3) return null;
      var year = int.parse(parts[2]);
      if (year < 100) year += 2000;
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Aggregate transactions by selected granularity (daily/weekly/monthly/yearly)
  List<Map<String, dynamic>> get _aggregatedData {
    final parsed = <DateTime, double>{};

    for (final item in _allData) {
      final d = _parseDate(item['date'] as String);
      if (d == null) continue;
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

      switch (_selectedFilter) {
        case 'daily':
          final key = DateTime(d.year, d.month, d.day);
          parsed[key] = (parsed[key] ?? 0.0) + amount;
          break;
        case 'weekly':
          final weekStart = d.subtract(Duration(days: d.weekday - 1));
          final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          parsed[key] = (parsed[key] ?? 0.0) + amount;
          break;
        case 'monthly':
          final key = DateTime(d.year, d.month);
          parsed[key] = (parsed[key] ?? 0.0) + amount;
          break;
        case 'yearly':
          final key = DateTime(d.year);
          parsed[key] = (parsed[key] ?? 0.0) + amount;
          break;
        default:
          final key = DateTime(d.year, d.month, d.day);
          parsed[key] = (parsed[key] ?? 0.0) + amount;
      }
    }

    final entries = parsed.entries.map((e) => {'date': e.key, 'amount': e.value}).toList();
    entries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    String monthName(int m) {
      const names = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return names[m];
    }

    return entries.map((e) {
      final DateTime dt = e['date'] as DateTime;
      String label;
      switch (_selectedFilter) {
        case 'daily':
          label = '${monthName(dt.month)} ${dt.day}, ${dt.year}';
          break;
        case 'weekly':
          final end = dt.add(const Duration(days: 6));
          label = '${monthName(dt.month)} ${dt.day}-${end.day} ${end.year}';
          break;
        case 'monthly':
          label = '${monthName(dt.month)} ${dt.year}';
          break;
        case 'yearly':
          label = '${dt.year}';
          break;
        default:
          label = '${monthName(dt.month)} ${dt.day}, ${dt.year}';
      }
      return {'label': label, 'amount': e['amount']};
    }).toList();
  }

  double get _totalRedeemed {
    // Total redeemed across all raw data
    return _allData
        .where((item) => item['type'] == 'Redemption')
        .fold(0.0, (double acc, item) {
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      return acc + amount;
    });
  }

  int get _batteryExchangeCount {
    return _allData.where((item) => item['type'] == 'Battery Exchange').length;
  }

  int _getItemsPerPage(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final reserved = 220.0;
    final rowHeight = 72.0;
    final available = screenHeight - reserved;
    final count = (available / rowHeight).floor();
    return count > 0 ? count : 1;
  }

  int get _totalPages {
    final itemsPerPage = _getItemsPerPage(context);
    final total = _aggregatedData.length;
    return (total / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedData {
    final all = _aggregatedData;
    final itemsPerPage = _getItemsPerPage(context);
    if (all.length <= itemsPerPage) return all;
    final start = (_currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return all.sublist(start, end > all.length ? all.length : end);
  }

  void _setFilter(String key) {
    setState(() => _selectedFilter = key);
  }

  Widget _buildTopCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: AppColors.dashboardAccent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'TOTAL Redeemed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₱ ${_totalRedeemed.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.battery_charging_full, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Batteries Exchanged',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildFilterChips() {
    const choices = ['daily', 'weekly', 'monthly', 'yearly'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(c[0].toUpperCase() + c.substring(1)),
              selected: selected,
              onSelected: (_) => _setFilter(c),
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

  Widget _buildHistoryList() {
    final items = _paginatedData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          // Paginated list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No transactions for $_selectedFilter',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDim,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            Text('₱ ${(item['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Modern pagination controls (only when rows exceed visible area)
          if (_aggregatedData.length > _getItemsPerPage(context))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous button
                  Container(
                    decoration: BoxDecoration(
                      color: _currentPage > 1 ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: _currentPage > 1 ? Colors.white : Colors.grey,
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page info with dots
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDim,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: List.generate(
                        _totalPages,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _currentPage = i + 1),
                            child: Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == i + 1 ? AppColors.primary : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Next button
                  Container(
                    decoration: BoxDecoration(
                      color: _currentPage < _totalPages ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      color: _currentPage < _totalPages ? Colors.white : Colors.grey,
                      onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Column(
        children: [
          const ScreenTitle(title: 'Transaction History'),
          _buildTopCard(),
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }
}
