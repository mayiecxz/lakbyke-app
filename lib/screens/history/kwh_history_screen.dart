import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/utils/constants.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';

class KwhHistoryScreen extends StatefulWidget {
  const KwhHistoryScreen({super.key});

  @override
  State<KwhHistoryScreen> createState() => _KwhHistoryScreenState();
}

class _KwhHistoryScreenState extends State<KwhHistoryScreen> {
  String _selectedFilter = 'daily';
  int _currentPage = 1;

  // Realistic sample data spanning multiple weeks
  final List<Map<String, dynamic>> _allData = const [
    {'date': '12/06/25', 'value': 1.23},
    {'date': '12/05/25', 'value': 0.95},
    {'date': '12/04/25', 'value': 1.15},
    {'date': '12/03/25', 'value': 0.55},
    {'date': '12/02/25', 'value': 1.25},
    {'date': '12/01/25', 'value': 1.21},
    {'date': '11/30/25', 'value': 1.06},
    {'date': '11/29/25', 'value': 0.88},
    {'date': '11/28/25', 'value': 1.45},
    {'date': '11/27/25', 'value': 0.72},
    {'date': '11/26/25', 'value': 1.33},
    {'date': '11/25/25', 'value': 0.91},
    {'date': '11/24/25', 'value': 1.18},
    {'date': '11/23/25', 'value': 0.67},
  ];

  DateTime? _parseDate(String s) {
    try {
      final parts = s.split('/');
      if (parts.length != 3) return null;
      var year = int.parse(parts[2]);
      if (year < 100) year += 2000; // treat '25' as 2025
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // Aggregate raw data into buckets depending on selected filter
  List<Map<String, dynamic>> get _aggregatedData {
    final parsed = <DateTime, double>{};

    for (final item in _allData) {
      final d = _parseDate(item['date'] as String);
      if (d == null) continue;
      final val = (item['value'] as double?) ?? 0.0;

      switch (_selectedFilter) {
        case 'daily':
          final key = DateTime(d.year, d.month, d.day);
          parsed[key] = (parsed[key] ?? 0.0) + val;
          break;
        case 'weekly':
          // week starting Monday
          final weekStart = d.subtract(Duration(days: d.weekday - 1));
          final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
          parsed[key] = (parsed[key] ?? 0.0) + val;
          break;
        case 'monthly':
          final key = DateTime(d.year, d.month);
          parsed[key] = (parsed[key] ?? 0.0) + val;
          break;
        case 'yearly':
          final key = DateTime(d.year);
          parsed[key] = (parsed[key] ?? 0.0) + val;
          break;
        default:
          final key = DateTime(d.year, d.month, d.day);
          parsed[key] = (parsed[key] ?? 0.0) + val;
      }
    }

    // Convert map to list and sort descending by key (most recent first)
    final entries = parsed.entries.map((e) => {'date': e.key, 'value': e.value}).toList();
    entries.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Format label for each aggregated row
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
      return {'label': label, 'value': e['value']};
    }).toList();
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

  double get _totalGenerated {
    // Total across all raw data
    return _allData.fold(0.0, (double acc, item) {
      final parsed = item['value'] as double? ?? 0.0;
      return acc + parsed;
    });
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
                      'No data for ${_selectedFilter}',
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
