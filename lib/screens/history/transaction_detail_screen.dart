import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';
import 'package:lakbyke_mobile/widgets/transaction_detail_modal.dart';
import 'package:lakbyke_mobile/widgets/index.dart';

/// Detail screen showing individual transactions for a selected period.
/// Reached when user taps a period (e.g. "January 2025") from Transaction history.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.periodLabel,
    required this.periodDate,
    required this.filterType,
    required this.totalAmount,
  });

  final String periodLabel;
  final DateTime periodDate;
  final String filterType;
  final double totalAmount;

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactionRepo = ref.read(transactionRepositoryProvider);
      final list = await transactionRepo.getDetailedTransactionsForPeriod(
        periodDate: widget.periodDate,
        filterType: widget.filterType,
      );
      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load transactions.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatRecordTimestamp(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy • HH:mm').format(date);
  }

  void _showEntryModal(Map<String, dynamic> transaction) {
    final timestamp = transaction['timestamp'] as DateTime?;
    if (timestamp == null) return;
    final amount = (transaction['payout'] as num?)?.toDouble() ??
        (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final label = _formatRecordTimestamp(timestamp);

    showDialog(
      context: context,
      builder: (context) => TransactionDetailModal(
        periodLabel: label,
        periodDate: timestamp,
        filterType: widget.filterType,
        totalAmount: amount,
        detailedTransactions: [transaction],
        isSingleEntry: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hPad = (w * 0.05).clamp(8.0, 20.0);
    final cardPad = (w * 0.045).clamp(12.0, 18.0);
    final iconMain = (w * 0.07).clamp(20.0, 28.0);
    final fontSizeMain = (w * 0.07).clamp(18.0, 28.0);
    final labelFontSize = (w * 0.032).clamp(11.0, 14.0);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
                        child: Container(
                          padding: EdgeInsets.all(cardPad),
                          decoration: BoxDecoration(
                            color: AppColors.homeAccent,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white, size: iconMain),
                                  SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                                  Text(
                                    'Total redeemed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: labelFontSize,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formatCompactCurrency(widget.totalAmount),
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: AppLoadingOverlay(message: 'Loading transactions...'))
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                                        const SizedBox(height: 16),
                                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 16),
                                        ElevatedButton(onPressed: _loadTransactions, child: const Text('Retry')),
                                      ],
                                    ),
                                  )
                                : _transactions.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No transactions in this period',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
                                        itemCount: _transactions.length,
                                        itemBuilder: (context, index) {
                                          final transaction = _transactions[index];
                                          final rowPadH = (w * 0.04).clamp(12.0, 16.0);
                                          final rowPadV = (w * 0.03).clamp(10.0, 14.0);
                                          final amount = (transaction['payout'] as num?)?.toDouble() ??
                                              (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: index < _transactions.length - 1 ? 12 : 0),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showEntryModal(transaction),
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
                                                          _formatRecordTimestamp(transaction['timestamp'] as DateTime?),
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            formatCompactCurrency(amount),
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
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            HeaderWithBack(title: widget.periodLabel),
          ],
        ),
      ),
    );
  }
}
