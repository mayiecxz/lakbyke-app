import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/features/history/providers/history_providers.dart';
import 'package:lakbyke_mobile/widgets/index.dart';
import 'package:lakbyke_mobile/widgets/energy_detail_modal.dart';

class KwhHistoryScreen extends ConsumerStatefulWidget {
  const KwhHistoryScreen({super.key});

  @override
  ConsumerState<KwhHistoryScreen> createState() => _KwhHistoryScreenState();
}

class _KwhHistoryScreenState extends ConsumerState<KwhHistoryScreen> {
  String _selectedFilter = 'daily';
  int _currentPage = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _aggregatedData = [];
  double _totalGenerated = 0.0;
  double _totalDistance = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final kwhRepo = ref.read(kwhRepositoryProvider);
      final results = await Future.wait([
        kwhRepo.getAggregatedData(_selectedFilter),
        kwhRepo.getTotalKwhGenerated(),
        kwhRepo.getTotalDistanceKm(),
      ]);

      setState(() {
        _aggregatedData = results[0] as List<Map<String, dynamic>>;
        _totalGenerated = results[1] as double;
        _totalDistance = results[2] as double;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data. Please try again.';
        _isLoading = false;
      });
    }
  }

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

  int _totalPages(BuildContext context) {
    final itemsPerPage = _getItemsPerPage(context);
    final total = _aggregatedData.length;
    return (total / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> _paginatedData(BuildContext context) {
    final all = _aggregatedData;
    final itemsPerPage = _getItemsPerPage(context);
    if (all.length <= itemsPerPage) return all;
    final start = (_currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return all.sublist(start, end > all.length ? all.length : end);
  }


  void _setFilter(String key) {
    if (_selectedFilter != key) {
      setState(() => _selectedFilter = key);
      _loadData(); // Reload data when filter changes
    }
  }

  Widget _buildTopCard() {
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
                    Icon(Icons.battery_full, color: Colors.white, size: iconMain),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'TOTAL Wh Generated',
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
                      _totalGenerated >= 1000000 ? '${formatCompactNumber(_totalGenerated / 1000)} kWh' : formatEnergy(_totalGenerated),
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
                    Icon(Icons.directions_bike, color: Colors.white, size: iconSec),
                    SizedBox(width: (w * 0.03).clamp(8.0, 12.0)),
                    Text(
                      'TOTAL km Travelled',
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
                      _totalDistance.abs() >= 1000 ? formatCompactNumber(_totalDistance, 1) : _totalDistance.toStringAsFixed(2),
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

  Widget _buildHistoryList(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingOverlay(message: 'Loading energy history...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _paginatedData(context);
    final w = MediaQuery.of(context).size.width;
    final listPadH = (w * 0.05).clamp(8.0, 20.0);
    final rowPadH = (w * 0.04).clamp(12.0, 16.0);
    final rowPadV = (w * 0.03).clamp(10.0, 14.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: listPadH, vertical: 12.0),
      child: Column(
        children: [
          // Paginated list (non-scrollable)
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No data for $_selectedFilter',
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
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item['label'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            () {
                                              final d = (item['distance'] as double? ?? 0.0);
                                              return '${d.abs() >= 1000 ? formatCompactNumber(d, 1) : d.toStringAsFixed(2)} km';
                                            }(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            () {
                                              final wh = item['value'] as double;
                                              return wh >= 1000000 ? '${formatCompactNumber(wh / 1000)} kWh' : formatEnergy(wh);
                                            }(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey[400], size: (w * 0.05).clamp(16.0, 20.0)),
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
                        _totalPages(context),
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
                      color: _currentPage < _totalPages(context) ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      color: _currentPage < _totalPages(context) ? Colors.white : Colors.grey,
                      onPressed: _currentPage < _totalPages(context) ? () => setState(() => _currentPage++) : null,
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

  Future<void> _showEnergyDetailModal(BuildContext context, Map<String, dynamic> item) async {
    try {
      final periodDate = item['date'] as DateTime?;
      if (periodDate == null) return;

      final energy = (item['value'] as num?)?.toDouble() ?? 0.0;
      final distance = (item['distance'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';

      final kwhRepo = ref.read(kwhRepositoryProvider);
      final detailedRecords = await kwhRepo.getDetailedRecordsForPeriod(
        periodDate: periodDate,
        filterType: _selectedFilter,
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => EnergyDetailModal(
            periodLabel: label,
            periodDate: periodDate,
            filterType: _selectedFilter,
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
            child: _buildHistoryList(context),
          ),
        ],
      ),
    );
  }
}
