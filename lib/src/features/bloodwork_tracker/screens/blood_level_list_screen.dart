//
//  blood_level_list_screen.dart
//  Screen that displays each hormone level with a mini graph
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';

/// Screen that shows an overview of all hormone levels
class BloodLevelListScreen extends ConsumerWidget {
  const BloodLevelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get only bloodwork type records for hormone graphs
    final bloodworkRecords = ref.watch(bloodworkTypeRecordsProvider);
    final isLoading = ref.watch(bloodworkLoadingProvider);
    final error = ref.watch(bloodworkErrorProvider);

    // Extract all unique hormone types from the data
    final Set<String> hormoneTypes = {};
    for (final record in bloodworkRecords) {
      for (final reading in record.hormoneReadings) {
        hormoneTypes.add(reading.name);
      }
    }

    // For backward compatibility
    if (bloodworkRecords.any((record) => record.estrogen != null)) {
      hormoneTypes.add('Estrogen');
    }
    if (bloodworkRecords.any((record) => record.testosterone != null)) {
      hormoneTypes.add('Testosterone');
    }

    // Sort hormone types alphabetically
    final sortedHormoneTypes = hormoneTypes.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hormone Levels'),
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
              : sortedHormoneTypes.isEmpty
                  ? _buildEmptyState()
                  : SafeArea(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedHormoneTypes.length,
                        itemBuilder: (context, index) {
                          final hormoneType = sortedHormoneTypes[index];
                          return _HormoneLevelTile(
                            hormoneName: hormoneType,
                            bloodworkRecords: bloodworkRecords,
                          );
                        },
                      ),
                    ),
    );
  }

  /// Builds the empty state view when no data exists
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.getOutlined('bloodwork'),
            size: 64,
            color: AppColors.secondary,
          ),
          SharedWidgets.verticalSpace(16),
          const Text(
            'No hormone data available',
            textAlign: TextAlign.center,
          ),
          SharedWidgets.horizontalSpace(),
          const Text(
            'Add bloodwork with hormone levels\nto see them displayed here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tile that displays information about a hormone level
class _HormoneLevelTile extends StatelessWidget {
  final String hormoneName;
  final List<Bloodwork> bloodworkRecords;

  const _HormoneLevelTile({
    required this.hormoneName,
    required this.bloodworkRecords,
  });

  @override
  Widget build(BuildContext context) {
    // Get readings for this hormone
    final List<MapEntry<DateTime, double>> readings = _getHormoneReadings();

    // Sort readings by date (oldest to newest for graph)
    readings.sort((a, b) => a.key.compareTo(b.key));

    // No data available
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get last reading and unit
    final lastReading = readings.last;
    String unit = _getHormoneUnit();

    // Calculate trends (if we have at least 2 points)
    final trendInfo = _calculateTrend(readings);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => NavigationService.goToBloodworkGraphWithHormone(
          context,
          hormoneName,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and last value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hormone name
                  Flexible(
                    child: Text(
                      hormoneName,
                      style: AppTextStyles.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Last value with trend indicator
                  Row(
                    children: [
                      if (trendInfo.showTrend)
                        Icon(
                          trendInfo.isIncreasing
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: trendInfo.isIncreasing
                              ? Colors.red
                              : Colors.green,
                          size: 16,
                        ),
                      SharedWidgets.horizontalSpace(4),
                      Text(
                        '${lastReading.value.toStringAsFixed(1)} $unit',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),

              SharedWidgets.horizontalSpace(),

              // Date of last reading
              Text(
                'Last recorded: ${DateFormat('MMM d, yyyy').format(lastReading.key)}',
                style: AppTextStyles.bodySmall,
              ),

              SharedWidgets.verticalSpace(16),

              // Mini chart
              SizedBox(
                height: 60,
                child: _buildMiniChart(readings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get all readings for this hormone
  List<MapEntry<DateTime, double>> _getHormoneReadings() {
    final readings = <MapEntry<DateTime, double>>[];

    for (final record in bloodworkRecords) {
      // Check in hormone readings list
      for (final reading in record.hormoneReadings) {
        if (reading.name == hormoneName) {
          readings.add(MapEntry(record.date, reading.value));
        }
      }

      // For backward compatibility
      if (hormoneName == 'Estrogen' && record.estrogen != null) {
        readings.add(MapEntry(record.date, record.estrogen!));
      }
      if (hormoneName == 'Testosterone' && record.testosterone != null) {
        readings.add(MapEntry(record.date, record.testosterone!));
      }
    }

    return readings;
  }

  /// Get the unit for this hormone type
  String _getHormoneUnit() {
    // First try to find it in the data
    for (final record in bloodworkRecords) {
      for (final reading in record.hormoneReadings) {
        if (reading.name == hormoneName) {
          return reading.unit;
        }
      }
    }

    // Fall back to default units
    switch (hormoneName) {
      case 'Estrogen':
        return 'pg/mL';
      case 'Testosterone':
        return 'ng/dL';
      default:
        return HormoneTypes.getDefaultUnit(hormoneName);
    }
  }

  /// Calculate trend information
  ({bool showTrend, bool isIncreasing, double percentChange}) _calculateTrend(
      List<MapEntry<DateTime, double>> readings) {
    if (readings.length < 2) {
      return (showTrend: false, isIncreasing: false, percentChange: 0);
    }

    final lastValue = readings.last.value;
    final previousValue = readings[readings.length - 2].value;

    if (previousValue == 0) {
      return (showTrend: false, isIncreasing: false, percentChange: 0);
    }

    final percentChange = ((lastValue - previousValue) / previousValue) * 100;
    final isIncreasing = lastValue > previousValue;

    return (
      showTrend: true,
      isIncreasing: isIncreasing,
      percentChange: percentChange.abs()
    );
  }

  /// Build a mini line chart
  Widget _buildMiniChart(List<MapEntry<DateTime, double>> readings) {
    // Extract values for min/max Y-axis
    final values = readings.map((e) => e.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        minX: 0,
        maxX: readings.length - 1.0,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(readings.length, (i) {
              return FlSpot(i.toDouble(), readings[i].value);
            }),
            isCurved: true,
            dotData: FlDotData(show: false),
            color: AppColors.primary,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}
