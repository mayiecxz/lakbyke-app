import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/services/transaction_service.dart';
import 'package:lakbyke_mobile/widgets/transaction_detail_modal.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'daily';
  int _currentPage = 1;
  final TransactionService _transactionService = TransactionService();

  int _getItemsPerPage(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    
    // Calculate reserved space for UI elements:
    // - AppBar/Header: ~60
    // - Top card: ~140 (padding + content)
    // - Filter chips: ~50
    // - Spacing: ~28 (8 + 12 + 8)
    // - Pagination controls (if shown): ~60
    // - Bottom padding: ~20
    // - SafeArea padding
    final reserved = 60.0 + 80.0 + 140.0 + 50.0 + 28.0 + 60.0 + 20.0 + padding.top + padding.bottom;
    
    // Row height: padding (14*2) + content (~44) = ~72
    final rowHeight = 72.0;
    
    final available = screenHeight - reserved;
    final count = (available / rowHeight).floor();
    return count > 0 ? count : 1;
  }

  int _totalPages(List<Map<String, dynamic>> aggregatedData, BuildContext context) {
    final itemsPerPage = _getItemsPerPage(context);
    final total = aggregatedData.length;
    return (total / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> _paginatedData(List<Map<String, dynamic>> aggregatedData, BuildContext context) {
    final all = aggregatedData;
    final itemsPerPage = _getItemsPerPage(context);
    if (all.length <= itemsPerPage) return all;
    final start = (_currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return all.sublist(start, end > all.length ? all.length : end);
  }

  void _setFilter(String key) {
    setState(() {
      _selectedFilter = key;
      _currentPage = 1; // Reset to first page when filter changes
    });
  }

  Widget _buildTopCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _transactionService.getTotalRedeemed(),
        _transactionService.getBatteryExchangeCount(),
      ]).then((results) => {
        'totalRedeemed': results[0] as double,
        'batteryExchangeCount': results[1] as int,
      }),
      builder: (context, snapshot) {
        final totalRedeemed = snapshot.data?['totalRedeemed'] ?? 0.0;
        final batteryExchangeCount = snapshot.data?['batteryExchangeCount'] ?? 0;
        final w = MediaQuery.of(context).size.width;
        final hPad = (w * 0.05).clamp(8.0, 20.0);
        final cardPad = (w * 0.045).clamp(12.0, 18.0);
        final iconMain = (w * 0.07).clamp(20.0, 28.0);
        final iconSec = (w * 0.06).clamp(18.0, 24.0);
        final fontSizeMain = (w * 0.07).clamp(18.0, 28.0);
        final fontSizeSec = (w * 0.06).clamp(16.0, 24.0);
        final labelFontSize = (w * 0.032).clamp(11.0, 14.0);
        final batteryStr = batteryExchangeCount >= 1000 ? formatCompactNumber(batteryExchangeCount, 0) : '$batteryExchangeCount';
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
                          formatCompactCurrency(totalRedeemed),
                          style: TextStyle(color: Colors.white, fontSize: fontSizeMain, fontWeight: FontWeight.bold),
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
                          batteryStr,
                          style: TextStyle(color: Colors.white, fontSize: fontSizeSec, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    const choices = ['daily', 'weekly', 'monthly', 'yearly'];
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = (screenWidth * 0.032).clamp(10.0, 14.0);
    final hPad = (screenWidth * 0.05).clamp(8.0, 20.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: choices.map((c) {
          final selected = c == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                c[0].toUpperCase() + c.substring(1),
                style: TextStyle(fontSize: fontSize),
              ),
              selected: selected,
              onSelected: (_) => _setFilter(c),
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

  Widget _buildHistoryList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _transactionService.getAggregatedData(_selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading transactions: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final aggregatedData = snapshot.data ?? [];
        final items = _paginatedData(aggregatedData, context);
        final w = MediaQuery.of(context).size.width;
        final listPadH = (w * 0.05).clamp(8.0, 20.0);
        final rowPadH = (w * 0.04).clamp(12.0, 16.0);
        final rowPadV = (w * 0.03).clamp(10.0, 14.0);
        final chevronSize = (w * 0.05).clamp(16.0, 20.0);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: listPadH, vertical: 12.0),
          child: Column(
            children: [
              // Paginated list (non-scrollable)
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions for $_selectedFilter',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showTransactionDetailModal(context, item, aggregatedData),
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
                                                formatCompactCurrency(item['amount'] as double),
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
                        }).toList(),
                      ),
              ),
              // Modern pagination controls (only when rows exceed visible area)
              if (aggregatedData.length > _getItemsPerPage(context))
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
                            _totalPages(aggregatedData, context),
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
                          color: _currentPage < _totalPages(aggregatedData, context) ? AppColors.primary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          color: _currentPage < _totalPages(aggregatedData, context) ? Colors.white : Colors.grey,
                          onPressed: _currentPage < _totalPages(aggregatedData, context) ? () => setState(() => _currentPage++) : null,
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
      },
    );
  }

  Future<void> _showTransactionDetailModal(
    BuildContext context,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> allData,
  ) async {
    try {
      final periodDate = item['date'] as DateTime?;
      if (periodDate == null) return;

      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';

      // Fetch detailed transactions for this period
      final detailedTransactions = await _transactionService.getDetailedTransactionsForPeriod(
        periodDate: periodDate,
        filterType: _selectedFilter,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => TransactionDetailModal(
            periodLabel: label,
            periodDate: periodDate,
            filterType: _selectedFilter,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Column(
        children: [
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
