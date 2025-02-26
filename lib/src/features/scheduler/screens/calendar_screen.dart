//
//  calendar_screen.dart
//
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/services/database_service.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/features/scheduler/screens/widgets/calendar.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Medication> _medications = [];
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicationsFromDB();
  }

  Future<void> _loadMedicationsFromDB() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the database service instance
      final dbService = DatabaseService();

      // Fetch medications from the database
      final medications = await dbService.getAllMedications();

      // Update state with fetched medications
      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors that might occur during database operations
      print('Error loading medications: $e');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load medications: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      // Initialize with empty list if database fails
      setState(() {
        _medications = [];
        _isLoading = false;
      });
    }
  }

  List<Medication> _getMedicationsForSelectedDay() {
    return _medications.where((med) {
      // Check if this medication is before start date
      // Strip time components for date-only comparison
      DateTime dateOnlyStart = DateUtils.dateOnly(med.startDate);
      DateTime dateOnlySelected = DateUtils.dateOnly(_selectedDay);

      if (dateOnlySelected.compareTo(dateOnlyStart) < 0) {
        return false;
      }

      // Check if this medication is due on the selected day
      String dayAbbr = _weekdayToAbbreviation(_selectedDay.weekday);
      if (!med.daysOfWeek.contains(dayAbbr)) {
        return false;
      }

      // For biweekly, check if this is the right week
      if (med.injectionDetails?.frequency == InjectionFrequency.biweekly) {
        // This is a simplified check. we still need proper week counting logic
        int weekNumber = _getWeekNumber(_selectedDay);
        return weekNumber % 2 == 0;
      }

      return true;
    }).toList();
  }

  String _weekdayToAbbreviation(int weekday) {
    return DateConstants.dayMap[weekday] ?? '';
  }

  int _getWeekNumber(DateTime date) {
    // Get the first day of the year
    final firstDayOfYear = DateTime(date.year, 1, 1);
    // Calculate days since first day of year
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    // Calculate week number (zero-indexed)
    return (daysSinceFirstDay / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Calendar'),
        elevation: 0,
        leading: IconButton(
            onPressed: () => NavigationService.goBack(context),
            icon: Icon(AppIcons.getIcon('schedule'))),
        actions: [
          IconButton(
            icon: Icon(AppIcons.getIcon('add')),
            onPressed:
                _loadMedicationsFromDB, // placeholder, later create add med/appt option
            //tooltip: 'Refresh medications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Custom calendar with injection indicators
                MedicationCalendar(
                  medications: _medications,
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                ),

                const Divider(),

                // Display injections due for selected day
                Expanded(
                  child: _buildInjectionsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildInjectionsList() {
    final injectionsForDay = _getMedicationsForSelectedDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                DateConstants.formatDate(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: injectionsForDay.isEmpty
              ? Center(
                  child: Text(
                    'Nothing scheduled for ${DateFormat('MM/dd/yy').format(_selectedDay)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: injectionsForDay.length,
                  itemBuilder: (context, index) {
                    final medication = injectionsForDay[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (medication.medicationType ==
                                MedicationType.injection)
                              Icon(AppIcons.getOutlined('vaccine'))
                            else
                              Icon(AppIcons.getOutlined('medication')),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                              child: Text(medication.name),
                              onPressed: () =>
                                  NavigationService.showMedicaitonDetails(
                                      context, medication),
                            ),
                            Text(
                              '${medication.dosage} @ ${DateFormat('h:mm a').format(medication.timeOfDay.first)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            //Text(
                            //     '${medication.id}-${_selectedDay.toIso8601String()}-${medication.timeOfDay}'),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
