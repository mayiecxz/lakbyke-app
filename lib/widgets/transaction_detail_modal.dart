import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal dialog showing detailed transaction information for a specific period
class TransactionDetailModal extends StatelessWidget {
  final String periodLabel;
  final DateTime periodDate;
  final String filterType; // 'daily', 'weekly', 'monthly', 'yearly'
  final double totalAmount; // Total redeemed amount
  final List<Map<String, dynamic>>? detailedTransactions; // Optional detailed transactions

  const TransactionDetailModal({
    super.key,
    required this.periodLabel,
    required this.periodDate,
    required this.filterType,
    required this.totalAmount,
    this.detailedTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 500 ? 500 : constraints.maxWidth * 0.9,
              maxHeight: constraints.maxHeight > 600 ? 600 : constraints.maxHeight * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              periodLabel,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF317263),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPeriodSubtitle(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main statistics
                        _buildTotalAmountCard(),
                        const SizedBox(height: 24),
                        
                        // Additional details if available
                        if (detailedTransactions != null && detailedTransactions!.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Transaction Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTransactionsList(),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Close button (fixed at bottom)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF317263),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPeriodSubtitle() {
    final dateFormat = DateFormat('MMMM d, yyyy');
    switch (filterType) {
      case 'daily':
        return dateFormat.format(periodDate);
      case 'weekly':
        final weekEnd = periodDate.add(const Duration(days: 6));
        return '${dateFormat.format(periodDate)} - ${dateFormat.format(weekEnd)}';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(periodDate);
      case 'yearly':
        return DateFormat('yyyy').format(periodDate);
      default:
        return dateFormat.format(periodDate);
    }
  }

  Widget _buildTotalAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF317263), Color(0xFF438775)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Total Redeemed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₱${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (detailedTransactions == null || detailedTransactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate stats from detailed transactions
    int transactionCount = detailedTransactions!.length;
    int batteryExchanges = 0;
    double avgAmount = 0.0;
    double maxAmount = 0.0;
    double totalPowerSubmitted = 0.0; // Total power submitted in Ah
    double avgVoltage = 0.0;
    double avgMntBattPercentage = 0.0;
    double avgStnBattPercentage = 0.0;
    double totalEnergyWh = 0.0; // Total energy in Wh (Ah * V)
    
    for (final transaction in detailedTransactions!) {
      final amount = (transaction['payout'] as num?)?.toDouble() ?? 
                     (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      
      avgAmount += amount;
      maxAmount = amount > maxAmount ? amount : maxAmount;
      
      // Power and energy data
      final powerSubmittedAh = (transaction['powerSubmitted_Ah'] as num?)?.toDouble() ?? 
                              (transaction['powerSubmitted'] as num?)?.toDouble() ?? 0.0;
      final voltage = (transaction['voltage'] as num?)?.toDouble() ?? 0.0;
      final mntBattPercentage = (transaction['mntBattPercentage'] as num?)?.toDouble() ?? 0.0;
      final stnBattPercentage = (transaction['stnBattPercentage'] as num?)?.toDouble() ?? 0.0;
      
      totalPowerSubmitted += powerSubmittedAh;
      avgVoltage += voltage;
      avgMntBattPercentage += mntBattPercentage;
      avgStnBattPercentage += stnBattPercentage;
      
      // Calculate energy in Wh: Wh = Ah * V
      if (voltage > 0 && powerSubmittedAh > 0) {
        totalEnergyWh += powerSubmittedAh * voltage;
      }
      
      // Check if it's a battery exchange transaction (has battery percentage data)
      if (mntBattPercentage > 0 || stnBattPercentage > 0) {
        batteryExchanges++;
      }
    }
    
    if (transactionCount > 0) {
      avgAmount /= transactionCount;
      avgVoltage /= transactionCount;
      avgMntBattPercentage /= transactionCount;
      avgStnBattPercentage /= transactionCount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Statistics
        const Text(
          'Summary Statistics',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF317263),
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Total Transactions', transactionCount.toString()),
        if (batteryExchanges > 0) _buildDetailRow('Battery Exchanges', batteryExchanges.toString()),
        if (avgAmount > 0) _buildDetailRow('Avg Payout', '₱${avgAmount.toStringAsFixed(2)}'),
        if (maxAmount > 0) _buildDetailRow('Max Payout', '₱${maxAmount.toStringAsFixed(2)}'),
        
        // Energy Statistics
        if (totalPowerSubmitted > 0 || totalEnergyWh > 0) ...[
          const SizedBox(height: 16),
          const Text(
            'Energy Statistics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF317263),
            ),
          ),
          const SizedBox(height: 12),
          if (totalPowerSubmitted > 0) _buildDetailRow('Total Power Submitted', '${totalPowerSubmitted.toStringAsFixed(2)} Ah'),
          if (totalEnergyWh > 0) _buildDetailRow('Total Energy Generated', '${totalEnergyWh.toStringAsFixed(2)} Wh'),
          if (avgVoltage > 0) _buildDetailRow('Avg Voltage', '${avgVoltage.toStringAsFixed(1)} V'),
        ],
        
        // Battery Statistics
        if (avgMntBattPercentage > 0 || avgStnBattPercentage > 0) ...[
          const SizedBox(height: 16),
          const Text(
            'Battery Statistics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF317263),
            ),
          ),
          const SizedBox(height: 12),
          if (avgMntBattPercentage > 0) _buildDetailRow('Avg Mount Battery', '${avgMntBattPercentage.toStringAsFixed(1)}%'),
          if (avgStnBattPercentage > 0) _buildDetailRow('Avg Station Battery', '${avgStnBattPercentage.toStringAsFixed(1)}%'),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
