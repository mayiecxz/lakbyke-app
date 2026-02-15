import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/core/constants/constants.dart';
import 'package:lakbyke_mobile/core/formatting/formatting.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/energy_detail_modal.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/index.dart';

/// Detail screen showing individual energy records for a selected period.
/// Reached when user taps a period (e.g. "January 2025") from KWH history.
class KwhDetailScreen extends ConsumerStatefulWidget {
  const KwhDetailScreen({
    super.key,
    required this.periodLabel,
    required this.periodDate,
    required this.filterType,
    required this.totalEnergy,
    required this.totalDistance,
  });

  final String periodLabel;
  final DateTime periodDate;
  final String filterType;
  final double totalEnergy;
  final double totalDistance;

  @override
  ConsumerState<KwhDetailScreen> createState() => _KwhDetailScreenState();
}

class _KwhDetailScreenState extends ConsumerState<KwhDetailScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final kwhRepo = ref.read(kwhRepositoryProvider);
      final records = await kwhRepo.getDetailedRecordsForPeriod(
        periodDate: widget.periodDate,
        filterType: widget.filterType,
      );
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load entries.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatRecordTimestamp(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy • HH:mm').format(date);
  }

  void _showEntryModal(Map<String, dynamic> record) {
    final timestamp = record['timestamp'] as DateTime?;
    if (timestamp == null) return;
    final wh = (record['totalWh'] as num?)?.toDouble() ?? 0.0;
    final distance = (record['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
    final label = _formatRecordTimestamp(timestamp);

    showDialog(
      context: context,
      builder: (context) => EnergyDetailModal(
        periodLabel: label,
        periodDate: timestamp,
        filterType: widget.filterType,
        totalEnergy: wh,
        totalDistance: distance,
        detailedRecords: [record],
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
    final iconSec = (w * 0.06).clamp(18.0, 24.0);
    final fontSizeMain = (w * 0.07).clamp(18.0, 28.0);
    final fontSizeSec = (w * 0.06).clamp(16.0, 24.0);
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.battery_full, color: Colors.white, size: iconMain),
                                      SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                                      Text(
                                        'Total energy',
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
                                        widget.totalEnergy >= 1000000
                                            ? '${formatCompactNumber(widget.totalEnergy / 1000)} kWh'
                                            : formatEnergy(widget.totalEnergy),
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
                                        'Total distance',
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
                                        widget.totalDistance.abs() >= 1000
                                            ? '${formatCompactNumber(widget.totalDistance, 1)} km'
                                            : '${widget.totalDistance.toStringAsFixed(2)} km',
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: AppLoadingOverlay(message: 'Loading entries...'))
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                                        const SizedBox(height: 16),
                                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 16),
                                        ElevatedButton(onPressed: _loadRecords, child: const Text('Retry')),
                                      ],
                                    ),
                                  )
                                : _records.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No entries in this period',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12.0),
                                        itemCount: _records.length,
                                        itemBuilder: (context, index) {
                                          final record = _records[index];
                                          final rowPadH = (w * 0.04).clamp(12.0, 16.0);
                                          final rowPadV = (w * 0.03).clamp(10.0, 14.0);
                                          final wh = (record['totalWh'] as num?)?.toDouble() ?? 0.0;
                                          final d = (record['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
                                          return Padding(
                                            padding: EdgeInsets.only(bottom: index < _records.length - 1 ? 12 : 0),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showEntryModal(record),
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
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              _formatRecordTimestamp(record['timestamp'] as DateTime?),
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '${d.abs() >= 1000 ? formatCompactNumber(d, 1) : d.toStringAsFixed(2)} km',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            wh >= 1000000
                                                                ? '${formatCompactNumber(wh / 1000)} kWh'
                                                                : formatEnergy(wh),
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
