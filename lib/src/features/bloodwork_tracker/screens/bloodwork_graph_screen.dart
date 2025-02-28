//
//  bloodwork_graph_screen.dart
//  Screen that displays hormone level graphs over time
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BloodworkGraphScreen extends ConsumerStatefulWidget {
  const BloodworkGraphScreen({super.key});

  @override
  ConsumerState<BloodworkGraphScreen> createState() =>
      _BloodworkGraphScreenState();
}

class _BloodworkGraphScreenState extends ConsumerState<BloodworkGraphScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Time range filter
  String _selectedTimeRange = 'All Time';
  final List<String> _timeRanges = [
    '3 Months',
    '6 Months',
    '1 Year',
    'All Time'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Bloodwork> _getFilteredData(List<Bloodwork> allRecords) {
    if (_selectedTimeRange == 'All Time') {
      return allRecords;
    }

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedTimeRange) {
      case '3 Months':
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6 Months':
        cutoffDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1 Year':
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return allRecords;
    }

    return allRecords
        .where((record) => record.date.isAfter(cutoffDate))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Use the bloodwork-type only provider for hormone graphs
    final bloodworkRecords = ref.watch(bloodworkTypeRecordsProvider);
    final isLoading = ref.watch(bloodworkLoadingProvider);
    final error = ref.watch(bloodworkErrorProvider);

    // Get filtered data based on time range
    final filteredRecords = _getFilteredData(bloodworkRecords);

    // Reverse the filtered records to show oldest to newest (left to right on chart)
    final chronologicalRecords = filteredRecords.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hormone Levels'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Estrogen'),
            Tab(text: 'Testosterone'),
          ],
        ),
        actions: [
          // Time range filter dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter time range',
            onSelected: (String value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _timeRanges.map((String range) {
                return PopupMenuItem<String>(
                  value: range,
                  child: Row(
                    children: [
                      Text(range),
                      if (_selectedTimeRange == range)
                        const Icon(Icons.check, size: 18)
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Text(
                'Error: $error',
                style: TextStyle(color: AppColors.error),
              ),
            )
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : chronologicalRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No bloodwork data available for the selected time range',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Only lab appointments with hormone levels are shown in graphs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Estrogen Chart
                        _buildChartContainer(
                          chronologicalRecords,
                          'Estrogen (pg/mL)',
                          AppColors.secondary,
                          (record) => record.estrogen,
                        ),

                        // Testosterone Chart
                        _buildChartContainer(
                          chronologicalRecords,
                          'Testosterone (ng/dL)',
                          AppColors.tertiary,
                          (record) => record.testosterone,
                        ),
                      ],
                    ),
    );
  }

  Widget _buildChartContainer(
    List<Bloodwork> records,
    String title,
    Color lineColor,
    double? Function(Bloodwork) valueGetter,
  ) {
    // Filter out records with null values for this hormone
    final validRecords =
        records.where((record) => valueGetter(record) != null).toList();

    if (validRecords.isEmpty) {
      return Center(
        child: Text('No data available for $title'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Time range: $_selectedTimeRange',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildLineChart(validRecords, lineColor, valueGetter),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<Bloodwork> records,
    Color lineColor,
    double? Function(Bloodwork) valueGetter,
  ) {
    // Get all values to calculate min and max for Y axis
    final values = records
        .map((record) => valueGetter(record))
        .where((value) => value != null)
        .map((value) => value!)
        .toList();

    if (values.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final minY = (values.reduce((a, b) => a < b ? a : b) * 0.8).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Show date for every other data point (or adjust as needed)
                if (value.toInt() >= 0 &&
                    value.toInt() < records.length &&
                    value.toInt() % 2 == 0) {
                  final date = records[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: AppTextStyles.labelSmall,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: AppTextStyles.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.outline.withOpacity(0.5)),
        ),
        minX: 0,
        maxX: records.length - 1.0,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _createSpots(records, valueGetter),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surface.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < records.length) {
                  final record = records[index];
                  final value = valueGetter(record)!;
                  final date = DateFormat('MM/dd/yyyy').format(record.date);
                  return LineTooltipItem(
                    '$date\n${value.toStringAsFixed(1)}',
                    AppTextStyles.bodySmall,
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _createSpots(
    List<Bloodwork> records,
    double? Function(Bloodwork) valueGetter,
  ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < records.length; i++) {
      final value = valueGetter(records[i]);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return spots;
  }
}
