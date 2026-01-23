import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
// import 'package:lakbyke_mobile/screens/template/chat_fab.dart';
import 'package:lakbyke_mobile/models/insights/insights_model.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsModel _insightsModel = InsightsModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsightsData();
  }

  Future<void> _loadInsightsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _insightsModel.loadInsightsData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      // floatingActionButton: const ChatFAB(), // Hidden for now
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInsightsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Activity Summary
                          _buildCurrentActivityCard(),
                          const SizedBox(height: 16),
                          
                          // Frequency Selector
                          _buildFrequencySelector(),
                          const SizedBox(height: 16),
                          
                          // Monthly Projection Card
                          _buildProjectionCard(),
                          const SizedBox(height: 16),
                          
                          // Comparison Chart
                          _buildComparisonChart(),
                          const SizedBox(height: 16),
                          
                          // Tips and Motivation
                          _buildMotivationCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Your Activity Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${_insightsModel.totalSessions}',
                    Icons.directions_bike,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Days',
                    '${_insightsModel.daysWithActivity}',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItemWithPeso(
                    'Avg/Session',
                    '₱${_insightsModel.averageEarningsPerSession.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            if (_insightsModel.weeklyAverageEarnings > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Average:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '₱${_insightsModel.weeklyAverageEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
              if (_insightsModel.weeklyAverageDistance > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly Distance:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      '${_insightsModel.weeklyAverageDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF317263),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF317263), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItemWithPeso(String label, String value) {
    return Column(
      children: [
        Text(
          '₱',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF317263),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Adjust Your Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sessions per week: ${_insightsModel.sessionsPerWeek}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _insightsModel.sessionsPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_insightsModel.sessionsPerWeek} sessions/week',
              activeColor: const Color(0xFF317263),
              onChanged: (value) {
                setState(() {
                  _insightsModel.sessionsPerWeek = value.round();
                  _insightsModel.calculateProjections();
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1x/week',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Daily',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard() {
    final increase = _insightsModel.projectedMonthlyEarnings - _insightsModel.currentMonthlyProjection;
    final increasePercent = _insightsModel.currentMonthlyProjection > 0
        ? (increase / _insightsModel.currentMonthlyProjection * 100)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF317263),
              const Color(0xFF317263).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Earnings Projection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projected',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₱${_insightsModel.projectedMonthlyEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (increase > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${increasePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Based on current activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₱${_insightsModel.currentMonthlyProjection.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Energy Generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${(_insightsModel.projectedMonthlyEnergy / 1000).toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_insightsModel.projectedMonthlyDistance > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${_insightsModel.projectedMonthlyDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    final analyticsData = _insightsModel.getAnalyticsData();
    
    // Even with no transactions, we should have data points (with zeros)
    // But check if we have any data points at all
    if (analyticsData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: const Color(0xFF317263)),
                  const SizedBox(width: 8),
                  const Text(
                    'Earnings Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF317263),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                alignment: Alignment.center,
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate max and min values (handle case where all values might be 0)
    final amounts = analyticsData.map((e) => e['amount'] as double).toList();
    final maxValue = amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 1.0;
    final minValue = amounts.isNotEmpty ? amounts.reduce((a, b) => a < b ? a : b) : 0.0;
    final chartHeight = 250.0;
    final leftPadding = 50.0; // Space for Y-axis labels
    final bottomPadding = 40.0; // Space for X-axis labels
    final topPadding = 20.0;
    final rightPadding = 20.0;

    // Calculate nice rounded Y-axis values (industry standard)
    final range = maxValue - minValue;
    final niceRange = InsightsModel.niceNumber(range, true);
    final niceMin = (minValue / niceRange).floor() * niceRange;
    final niceMax = (maxValue / niceRange).ceil() * niceRange;
    final niceStep = InsightsModel.niceNumber((niceMax - niceMin) / 5, false);
    final yAxisSteps = ((niceMax - niceMin) / niceStep).ceil();
    final actualMax = niceMin + (yAxisSteps * niceStep);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: const Color(0xFF317263)),
                const SizedBox(width: 8),
                const Text(
                  'Earnings Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF317263),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter chips
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: ['past week', 'past month', 'past year', 'all time'].map((filter) {
                final selected = _insightsModel.analyticsFilter == filter;
                String displayLabel;
                switch (filter) {
                  case 'past week':
                    displayLabel = 'Week';
                    break;
                  case 'past month':
                    displayLabel = 'Month';
                    break;
                  case 'past year':
                    displayLabel = 'Year';
                    break;
                  case 'all time':
                    displayLabel = 'All Time';
                    break;
                  default:
                    displayLabel = filter;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      displayLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _insightsModel.analyticsFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF317263),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Proper line graph with axes
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  // Y-axis labels (vertical axis on the left)
                  Positioned(
                    left: 0,
                    top: topPadding,
                    bottom: bottomPadding,
                    width: leftPadding - 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(yAxisSteps + 1, (index) {
                        final value = actualMax - (index * niceStep);
                        return Text(
                          '₱${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        );
                      }).reversed.toList(),
                    ),
                  ),
                  // Chart area with proper line graph
                  Positioned(
                    left: leftPadding,
                    right: rightPadding,
                    top: topPadding,
                    bottom: bottomPadding,
                    child: CustomPaint(
                      painter: ProfessionalLineChartPainter(
                        data: analyticsData.map((e) => e['amount'] as double).toList(),
                        minValue: niceMin,
                        maxValue: actualMax,
                        color: const Color(0xFF317263),
                      ),
                    ),
                  ),
                  // X-axis labels (horizontal axis at the bottom)
                  Positioned(
                    left: leftPadding,
                    right: rightPadding,
                    bottom: 0,
                    height: bottomPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: analyticsData.asMap().entries.map((entry) {
                        final item = entry.value;
                        final label = item['label'] as String;
                        
                        return Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMotivationCard() {
    final increase = _insightsModel.projectedMonthlyEarnings - _insightsModel.currentMonthlyProjection;
    String motivationText = '';
    String tipText = '';

    if (increase > 0) {
      motivationText = 'By increasing to ${_insightsModel.sessionsPerWeek} sessions per week, you could earn an additional ₱${increase.toStringAsFixed(2)} per month!';
      tipText = '💡 Tip: Consistency is key! Even small increases in frequency can lead to significant earnings over time.';
    } else if (_insightsModel.totalSessions == 0) {
      motivationText = 'Start your first session to begin earning! Every ride counts towards your monthly projection.';
      tipText = '💡 Tip: Begin with 1-2 sessions per week and gradually increase as you build your routine.';
    } else {
      motivationText = 'Keep up the great work! Maintain your current activity level to reach your monthly goal.';
      tipText = '💡 Tip: Try to maintain a consistent schedule. Regular biking sessions help build momentum!';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Motivation & Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              motivationText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                tipText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Professional line chart painter with proper axes and grid lines
class ProfessionalLineChartPainter extends CustomPainter {
  final List<double> data;
  final double minValue;
  final double maxValue;
  final Color color;

  ProfessionalLineChartPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= minValue) return;

    final chartWidth = size.width;
    final chartHeight = size.height;
    final valueRange = maxValue - minValue;
    
    // Draw horizontal grid lines (Y-axis grid)
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Calculate number of grid lines (typically 4-6 for readability)
    final numGridLines = 5;
    for (int i = 0; i <= numGridLines; i++) {
      final y = (chartHeight / numGridLines) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(chartWidth, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines at data points (X-axis grid)
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;
    for (int i = 0; i < data.length; i++) {
      final x = (i * stepX).toDouble();
      canvas.drawLine(
        Offset(x, 0.0),
        Offset(x, chartHeight),
        gridPaint,
      );
    }

    // Draw axes (X and Y axis lines)
    final axisPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // X-axis (bottom)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(chartWidth, 0),
      axisPaint,
    );
    
    // Y-axis (left)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, chartHeight),
      axisPaint,
    );

    // Line paint for the data line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Point paint with outline
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final pointOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Calculate data points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i * stepX).toDouble();
      // Normalize value to chart height (inverted Y-axis: 0 at bottom, max at top)
      final normalizedValue = (data[i] - minValue) / valueRange;
      final y = (chartHeight - (normalizedValue * chartHeight)).toDouble();
      points.add(Offset(x, y));
    }

    // Draw the data line with smooth curve (optional: can use quadratic bezier for smoother curves)
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      
      // Use straight lines (industry standard for time series)
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, linePaint);
    }

    // Draw data points with white outline for better visibility
    for (final point in points) {
      // Draw white outline circle
      canvas.drawCircle(point, 6.0, pointOutlinePaint);
      // Draw colored point
      canvas.drawCircle(point, 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(ProfessionalLineChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.minValue != minValue ||
           oldDelegate.maxValue != maxValue || 
           oldDelegate.color != color;
  }
}
