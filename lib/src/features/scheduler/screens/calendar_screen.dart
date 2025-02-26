//
//  calendar_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/services/database_service.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  List<Medication> _medications = [];
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMedicationsFromDB();

    // Load taken medications data after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTakenMedicationsForSelectedDay();
    });
  }

  // Load taken medications for the selected day
  void _loadTakenMedicationsForSelectedDay() {
    final normalizedDate =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    ref
        .read(medicationTakenProvider.notifier)
        .loadTakenMedicationsForDate(normalizedDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        // Calculate if this is the correct week for biweekly schedule
        final daysSinceStart =
            dateOnlySelected.difference(dateOnlyStart).inDays;
        final weeksSinceStart = daysSinceStart ~/ 7;
        return weeksSinceStart % 2 == 0; // Improved biweekly logic
      }

      return true;
    }).toList();
  }

  String _weekdayToAbbreviation(int weekday) {
    return DateConstants.dayMap[weekday] ?? '';
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
            onPressed: _loadMedicationsFromDB, // Refresh medications
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    MedicationCalendar(
                      medications: _medications,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                        // Load taken medications when day changes
                        _loadTakenMedicationsForSelectedDay();
                      },
                    ),

                    const Divider(),

                    // Display medications for selected day
                    _buildMedicationsListContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMedicationsListContent() {
    final medicationsForDay = _getMedicationsForSelectedDay();
    final formattedDate = DateFormat('MM/dd/yy').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            DateConstants.formatDate(_selectedDay),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // Container with minimum height to ensure it's still visible when empty
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.only(bottom: 24),
          child: medicationsForDay.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Nothing scheduled for $formattedDate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : Column(
                  children: medicationsForDay
                      .map((medication) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildMedicationCard(medication),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    // Create a normalized date for the selected day
    final normalizedDate =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication type icon
            Icon(medication.medicationType == MedicationType.injection
                ? AppIcons.getOutlined('vaccine')
                : AppIcons.getOutlined('medication')),

            const SizedBox(width: 16),

            // Medication details with clickable name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => NavigationService.showMedicaitonDetails(
                        context, medication),
                    child: Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display dosage
                      Text(
                        'Dosage: ${medication.dosage}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      // Display all times medication is taken
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time${medication.timeOfDay.length > 1 ? 's' : ''}:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          // Map through times and include checkmark if taken
                          ...medication.timeOfDay.map((time) {
                            // Format time the same way as in the UI
                            final timeStr =
                                TimeOfDay.fromDateTime(time).format(context);

                            // Create the key for the medication taken provider
                            final medicationKey =
                                '${medication.id}-${normalizedDate.toIso8601String()}-$timeStr';

                            // Check if this medication was taken
                            final isTaken = ref.watch(
                                isMedicationTakenProvider(medicationKey));

                            return Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Row(
                                children: [
                                  Text(
                                    timeStr,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  if (isTaken)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        AppIcons.getIcon('check_circle'),
                                        color: AppColors.tertiary,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom calendar widget showing medication schedules with visual indicators
class MedicationCalendar extends StatefulWidget {
  final List<Medication> medications;
  final Function(DateTime) onDaySelected;

  const MedicationCalendar({
    Key? key,
    required this.medications,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  _MedicationCalendarState createState() => _MedicationCalendarState();
}

class _MedicationCalendarState extends State<MedicationCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Set<DateTime> _injectionDueDates;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _updateInjectionDates();
  }

  @override
  void didUpdateWidget(MedicationCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.medications != oldWidget.medications) {
      _updateInjectionDates();
    }
  }

  void _updateInjectionDates() {
    _injectionDueDates = _calculateInjectionDueDates(widget.medications);
  }

  @override
  Widget build(BuildContext context) {
    const Color injectionDueColor = AppTheme.orangeDark;
    return Padding(
      padding: AppTheme.standardScreenMargins,
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: AppTextStyles.titleMedium,
          leftChevronIcon: Icon(AppIcons.getIcon('chevron_left')),
          rightChevronIcon: Icon(AppIcons.getIcon('chevron_right')),
          headerPadding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.lightgreyDark.withAlpha(40),
          ),
        ),
        daysOfWeekHeight: 40,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTextStyles.titleSmall,
          weekendStyle: AppTextStyles.titleSmall,
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: AppTextStyles.labelMedium,
          weekendTextStyle: AppTextStyles.labelMedium,
          // Add transparency to out-of-month days
          outsideTextStyle: AppTextStyles.labelMedium.copyWith(
            color: AppTextStyles.labelMedium.color?.withAlpha(120),
          ),

          // Today styling
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          todayTextStyle:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),

          // Selected day styling
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
              color: AppColors.onPrimary, fontWeight: FontWeight.bold),

          // Cell margin for better spacing
          cellMargin: const EdgeInsets.all(4),
          cellPadding: const EdgeInsets.all(0),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          // Custom day builder to show injection indicators
          defaultBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day, _injectionDueDates);

            if (hasInjection) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: injectionDueColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: injectionDueColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }
            return null; // Use default rendering for other days
          },
          // Make sure injection indicators still show for selected days
          selectedBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day, _injectionDueDates);

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Change the background color to injectionDueColor when selected day has injection
                color: hasInjection ? injectionDueColor : AppColors.primary,
                border: hasInjection
                    ? Border.all(color: injectionDueColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          // Custom "today" builder
          todayBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day, _injectionDueDates);

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(40),
                border: Border.all(
                  color: hasInjection ? injectionDueColor : AppColors.primary,
                  width: hasInjection ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: hasInjection ? injectionDueColor : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          // Add builder for out-of-month days to add transparency and apply injection rules
          outsideBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day, _injectionDueDates);

            if (hasInjection) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: injectionDueColor.withAlpha(160), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: injectionDueColor.withAlpha(160),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: Text(
                '${day.day}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppTextStyles.labelMedium.color?.withAlpha(100),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _hasInjectionDue(DateTime date, Set<DateTime> injectionDates) {
    // Compare just the date part, not time
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return injectionDates.any((injectionDate) {
      final normalizedInjectionDate = DateTime(
        injectionDate.year,
        injectionDate.month,
        injectionDate.day,
      );
      return normalizedInjectionDate.isAtSameMomentAs(normalizedDate);
    });
  }
}

/// Helper functions for calculating injection dates

// Helper method to calculate which days have injections due
Set<DateTime> _calculateInjectionDueDates(List<Medication> medications) {
  Set<DateTime> injectionDates = {};
  final now = DateTime.now();
  final today =
      DateTime(now.year, now.month, now.day); // Normalize to start of day

  // Look back a year and ahead a year (total 730 days)
  final startDate = today.subtract(const Duration(days: 365));
  const daysToCalculate = 730; // 365 days back + 365 days forward

  for (var medication in medications) {
    if (medication.medicationType == MedicationType.injection) {
      // Use medication's start date if it's later than our lookback date
      final medicationStartDate = DateTime(medication.startDate.year,
          medication.startDate.month, medication.startDate.day);

      // Use the later of our lookback date or the medication start date
      final calculationStartDate = medicationStartDate.isAfter(startDate)
          ? medicationStartDate
          : startDate;

      if (medication.injectionDetails?.frequency == InjectionFrequency.weekly) {
        _addWeeklyInjections(
          injectionDates,
          medication.daysOfWeek,
          calculationStartDate,
          daysToCalculate,
          7, // Every 7 days
        );
      } else if (medication.injectionDetails?.frequency ==
          InjectionFrequency.biweekly) {
        _addWeeklyInjections(
          injectionDates,
          medication.daysOfWeek,
          calculationStartDate,
          daysToCalculate,
          14, // Every 14 days
        );
      }
    }
  }
  return injectionDates;
}

// Calculate injection dates based on frequency and selected days
void _addWeeklyInjections(
  Set<DateTime> dates,
  Set<String> daysOfWeek,
  DateTime startDate,
  int daysToLookAhead,
  int frequency,
) {
  // Convert days of week to int representation (0-6)
  Set<int> weekdayNumbers = daysOfWeek
      .map((day) => DateConstants.dayAbbreviationToWeekday(day))
      .toSet();

  // Calculate reference date for biweekly calculation - normalized to start of day
  final referenceDate =
      DateTime(startDate.year, startDate.month, startDate.day);

  // Look through each day in the period
  for (int i = 0; i < daysToLookAhead; i++) {
    DateTime currentDate = startDate.add(Duration(days: i));

    // Check if this day matches any of the target weekdays
    if (weekdayNumbers.contains(currentDate.weekday % 7)) {
      // For biweekly, we need to check if this is the right week
      bool isCorrectFrequencyWeek = true;

      if (frequency == 14) {
        // Calculate days since reference date
        final daysSinceReference = currentDate.difference(referenceDate).inDays;
        // Check if we're in the correct week
        isCorrectFrequencyWeek = (daysSinceReference ~/ 7) % 2 == 0;
      }

      if (isCorrectFrequencyWeek) {
        dates.add(currentDate);
      }
    }
  }
}
