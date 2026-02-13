import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:intl/intl.dart';

/// Modal dialog showing detailed energy information for a specific period
class EnergyDetailModal extends StatelessWidget {
  final String periodLabel;
  final DateTime periodDate;
  final String filterType; // 'daily', 'weekly', 'monthly', 'yearly'
  final double totalEnergy; // in Wh
  final double totalDistance; // in km
  final List<Map<String, dynamic>>? detailedRecords; // Optional detailed records
  /// When true, modal is showing a single entry (e.g. from detail screen); subtitle is simplified.
  final bool isSingleEntry;

  const EnergyDetailModal({
    super.key,
    required this.periodLabel,
    required this.periodDate,
    required this.filterType,
    required this.totalEnergy,
    required this.totalDistance,
    this.detailedRecords,
    this.isSingleEntry = false,
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
                              isSingleEntry ? 'Single entry' : _getPeriodSubtitle(),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.bolt,
                                label: 'Energy Generated',
                                value: totalEnergy >= 1000000 ? '${formatCompactNumber(totalEnergy / 1000)} kWh' : formatEnergy(totalEnergy),
                                color: Colors.amber[700]!,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.straighten,
                                label: 'Distance',
                                value: '${totalDistance.abs() >= 1000 ? formatCompactNumber(totalDistance, 1) : totalDistance.toStringAsFixed(2)} km',
                                color: Colors.blue[700]!,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Additional details if available
                        if (detailedRecords != null && detailedRecords!.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Additional Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailsList(),
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList() {
    if (detailedRecords == null || detailedRecords!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate averages and other stats from detailed records
    double avgPower = 0.0;
    double maxPower = 0.0;
    double avgSpeed = 0.0;
    double maxSpeed = 0.0;
    int recordCount = detailedRecords!.length;
    
    for (final record in detailedRecords!) {
      final power = (record['powerGeneratedInWatts'] as num?)?.toDouble() ?? 0.0;
      final speed = (record['speedKmh'] as num?)?.toDouble() ?? 0.0;
      
      avgPower += power;
      maxPower = power > maxPower ? power : maxPower;
      avgSpeed += speed;
      maxSpeed = speed > maxSpeed ? speed : maxSpeed;
    }
    
    if (recordCount > 0) {
      avgPower /= recordCount;
      avgSpeed /= recordCount;
    }

    return Column(
      children: [
        _buildDetailRow('Records', recordCount >= 1000 ? formatCompactNumber(recordCount, 0) : recordCount.toString()),
        if (avgPower > 0) _buildDetailRow('Avg Power', '${avgPower.abs() >= 1000 ? formatCompactNumber(avgPower, 1) : avgPower.toStringAsFixed(2)} W'),
        if (maxPower > 0) _buildDetailRow('Max Power', '${maxPower.abs() >= 1000 ? formatCompactNumber(maxPower, 1) : maxPower.toStringAsFixed(2)} W'),
        if (avgSpeed > 0) _buildDetailRow('Avg Speed', '${avgSpeed.abs() >= 1000 ? formatCompactNumber(avgSpeed, 1) : avgSpeed.toStringAsFixed(1)} km/h'),
        if (maxSpeed > 0) _buildDetailRow('Max Speed', '${maxSpeed.abs() >= 1000 ? formatCompactNumber(maxSpeed, 1) : maxSpeed.toStringAsFixed(1)} km/h'),
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
