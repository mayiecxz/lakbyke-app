import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
import 'package:lakbyke_mobile/services/kwh_service.dart';

class KwhHistoryScreen extends StatefulWidget {
  const KwhHistoryScreen({super.key});

  @override
  State<KwhHistoryScreen> createState() => _KwhHistoryScreenState();
}

class _KwhHistoryScreenState extends State<KwhHistoryScreen> {
  final KwhService _kwhService = KwhService();
  String _selectedFilter = 'daily';
  int _currentPage = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _aggregatedData = [];
  double _totalGenerated = 0.0;
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
      // Load aggregated data and total in parallel
      final results = await Future.wait([
        _kwhService.getAggregatedData(_selectedFilter),
        _kwhService.getTotalKwhGenerated(),
      ]);

      setState(() {
        _aggregatedData = results[0] as List<Map<String, dynamic>>;
        _totalGenerated = results[1] as double;
        _isLoading = false;
        _currentPage = 1; // Reset to first page when filter changes
      });
    } catch (e) {
      print('Error loading kWh history: $e');
      setState(() {
        _errorMessage = 'Failed to load data. Please try again.';
        _isLoading = false;
      });
    }
  }

  int _getItemsPerPage(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Determine how many rows fit on screen. Rows will only be paginated
    // if the number of aggregated rows exceeds this value.
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
    if (_selectedFilter != key) {
      setState(() => _selectedFilter = key);
      _loadData(); // Reload data when filter changes
    }
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.battery_full, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'TOTAL kWh Generated',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              _totalGenerated.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const choices = ['yearly', 'monthly', 'weekly', 'daily'];
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
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
                      'No data for $_selectedFilter',
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
                            Flexible(child: Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 12),
                            Text('${(item['value'] as double).toStringAsFixed(2)} kWh', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          const ScreenTitle(title: 'kWh History'),
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
