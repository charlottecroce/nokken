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
  final String? selectedHormone;

  const BloodworkGraphScreen({
    super.key,
    this.selectedHormone,
  });

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

  // Available hormone types
  late List<String> _hormoneTypes;
  late String _selectedHormone;

  @override
  void initState() {
    super.initState();

    // Initialize with the selected hormone or default to first available
    _selectedHormone = widget.selectedHormone ?? '';

    // Extract hormone types from data
    final bloodworkRecords = ref.read(bloodworkTypeRecordsProvider);
    _hormoneTypes = _extractHormoneTypes(bloodworkRecords);

    // If no selected hormone or selected hormone not in the list, use first one
    if (_selectedHormone.isEmpty || !_hormoneTypes.contains(_selectedHormone)) {
      _selectedHormone = _hormoneTypes.isNotEmpty ? _hormoneTypes[0] : '';
    }

    // Initialize tab controller with the number of available hormone types
    _tabController = TabController(
      length: _hormoneTypes.length,
      vsync: this,
      initialIndex: _selectedHormone.isNotEmpty
          ? _hormoneTypes.indexOf(_selectedHormone)
          : 0,
    );

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_hormoneTypes.isNotEmpty) {
        setState(() {
          _selectedHormone = _hormoneTypes[_tabController.index];
        });
      }
    });
  }

  /// Extract all available hormone types from records
  List<String> _extractHormoneTypes(List<Bloodwork> records) {
    // Set to store unique hormone types
    final Set<String> hormoneSet = {};

    // Extract from hormone readings
    for (final record in records) {
      for (final reading in record.hormoneReadings) {
        hormoneSet.add(reading.name);
      }
    }

    // For backward compatibility
    if (records.any((record) => record.estrogen != null)) {
      hormoneSet.add('Estrogen');
    }
    if (records.any((record) => record.testosterone != null)) {
      hormoneSet.add('Testosterone');
    }

    // Sort alphabetically
    final hormoneList = hormoneSet.toList()..sort();
    return hormoneList;
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

    // Check if we need to update the hormone types and tabs
    final newHormoneTypes = _extractHormoneTypes(bloodworkRecords);
    if (newHormoneTypes.length != _hormoneTypes.length ||
        !newHormoneTypes.every((e) => _hormoneTypes.contains(e))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hormoneTypes = newHormoneTypes;
          // Try to keep the selected hormone if possible
          final selectedIndex = newHormoneTypes.contains(_selectedHormone)
              ? newHormoneTypes.indexOf(_selectedHormone)
              : 0;

          // Recreate tab controller with new length
          _tabController.dispose();
          _tabController = TabController(
            length: newHormoneTypes.length,
            vsync: this,
            initialIndex: selectedIndex,
          );
          _selectedHormone =
              newHormoneTypes.isNotEmpty ? newHormoneTypes[selectedIndex] : '';
        });
      });
    }

    // Get filtered data based on time range
    final filteredRecords = _getFilteredData(bloodworkRecords);

    // Reverse the filtered records to show oldest to newest (left to right on chart)
    final chronologicalRecords = filteredRecords.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selectedHormone.isNotEmpty ? _selectedHormone : 'Blood Levels'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: _hormoneTypes.length > 2,
          tabs: _hormoneTypes.map((type) => Tab(text: type)).toList(),
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
              : _selectedHormone.isEmpty || chronologicalRecords.isEmpty
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
                      children: _hormoneTypes
                          .map(
                            (hormoneType) => _buildChartContainer(
                              chronologicalRecords,
                              hormoneType,
                              _getHormoneColor(hormoneType),
                              (record) => _getHormoneValue(record, hormoneType),
                              _getHormoneUnit(
                                  chronologicalRecords, hormoneType),
                            ),
                          )
                          .toList(),
                    ),
    );
  }

  /// Get the appropriate color for this hormone type
  Color _getHormoneColor(String hormoneType) {
    switch (hormoneType) {
      case 'Estrogen':
        return AppColors.secondary;
      case 'Testosterone':
        return AppColors.tertiary;
      default:
        // Generate consistent colors for other hormones
        final hash = hormoneType.hashCode;
        return Color.fromARGB(
          255,
          (hash & 0xFF),
          ((hash >> 8) & 0xFF),
          ((hash >> 16) & 0xFF),
        );
    }
  }

  /// Get the hormone value from a record
  double? _getHormoneValue(Bloodwork record, String hormoneType) {
    // First check in hormone readings
    for (final reading in record.hormoneReadings) {
      if (reading.name == hormoneType) {
        return reading.value;
      }
    }

    // For backward compatibility
    if (hormoneType == 'Estrogen') {
      return record.estrogen;
    } else if (hormoneType == 'Testosterone') {
      return record.testosterone;
    }

    return null;
  }

  /// Get the unit for this hormone type
  String _getHormoneUnit(List<Bloodwork> records, String hormoneType) {
    // First try to find it in the data
    for (final record in records) {
      for (final reading in record.hormoneReadings) {
        if (reading.name == hormoneType) {
          return reading.unit;
        }
      }
    }

    // Fall back to default units
    switch (hormoneType) {
      case 'Estrogen':
        return 'pg/mL';
      case 'Testosterone':
        return 'ng/dL';
      default:
        return HormoneTypes.getDefaultUnit(hormoneType);
    }
  }

  Widget _buildChartContainer(
    List<Bloodwork> records,
    String title,
    Color lineColor,
    double? Function(Bloodwork) valueGetter,
    String unit,
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
            '$title ($unit)',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Time range: $_selectedTimeRange',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildLineChart(validRecords, lineColor, valueGetter, unit),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<Bloodwork> records,
    Color lineColor,
    double? Function(Bloodwork) valueGetter,
    String unit,
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
          border: Border.all(color: AppColors.outline.withAlpha(150)),
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
              color: lineColor.withAlpha(40),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.surface.withAlpha(80),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < records.length) {
                  final record = records[index];
                  final value = valueGetter(record)!;
                  final date = DateFormat('MM/dd/yyyy').format(record.date);
                  return LineTooltipItem(
                    '$date\n${value.toStringAsFixed(1)} $unit',
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
