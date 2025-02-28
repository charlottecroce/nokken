//
//  calendar_screen.dart
//  Monthly calendar view with medication schedule visualization
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/features/medication_tracker/services/medication_schedule_service.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
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

  /// Load taken medications for the selected day
  void _loadTakenMedicationsForSelectedDay() {
    // Use normalized date for consistency with MedicationDose model
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

  /// Load medications directly from the database
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

  /// Filter medications to those that should appear on the selected day
  /// Now using the MedicationScheduleService
  List<Medication> _getMedicationsForSelectedDay() {
    return MedicationScheduleService.getMedicationsForDate(
        _medications, _selectedDay);
  }

  /// Get bloodwork records for the selected day
  List<Bloodwork> _getBloodworkForSelectedDay() {
    final bloodworkRecords = ref.watch(bloodworkRecordsProvider);
    return bloodworkRecords.where((record) {
      // Compare just the date part (not time)
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      final selectedDate =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      return recordDate.isAtSameMomentAs(selectedDate);
    }).toList();
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
                    // Calendar component
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

  /// Build the list of medications and bloodwork for the selected day
  Widget _buildMedicationsListContent() {
    final medicationsForDay = _getMedicationsForSelectedDay();
    final bloodworkForDay = _getBloodworkForSelectedDay();
    final formattedDate = DateTimeFormatter.formatDateDDMMYY(_selectedDay);

    final bool hasItems =
        bloodworkForDay.isNotEmpty || medicationsForDay.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            DateTimeFormatter.formatDateMMMDDYYYY(_selectedDay),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // Container with minimum height to ensure it's still visible when empty
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.only(bottom: 24),
          child: !hasItems
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
                  children: [
                    // Bloodwork records first
                    ...bloodworkForDay.map((bloodwork) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildBloodworkCard(bloodwork),
                        )),

                    // Then medications
                    ...medicationsForDay.map((medication) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildMedicationCard(medication),
                        )),
                  ],
                ),
        ),
      ],
    );
  }

  /// Build a card for an individual bloodwork record
  Widget _buildBloodworkCard(Bloodwork bloodwork) {
    final isDateInFuture = DateTime(
      bloodwork.date.year,
      bloodwork.date.month,
      bloodwork.date.day,
    ).isAfter(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bloodwork icon
            Icon(Icons.science_outlined, color: Colors.red),

            SharedWidgets.verticalSpace(16),

            // Bloodwork details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => NavigationService.goToBloodworkAddEdit(
                      context,
                      bloodwork: bloodwork,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Lab Appointment',
                          style: AppTextStyles.titleLarge,
                        ),
                        if (isDateInFuture) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.info.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Scheduled',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SharedWidgets.verticalSpace(),
                  // If future date, show scheduled message
                  if (isDateInFuture)
                    Text(
                      'Lab appointment scheduled',
                      style: AppTextStyles.bodyMedium,
                    )
                  // Otherwise show hormone levels if available
                  else ...[
                    if (bloodwork.estrogen != null)
                      Text(
                          'Estrogen: ${bloodwork.estrogen!.toStringAsFixed(1)} pg/mL'),
                    if (bloodwork.testosterone != null)
                      Text(
                          'Testosterone: ${bloodwork.testosterone!.toStringAsFixed(1)} ng/dL'),
                    if (bloodwork.estrogen == null &&
                        bloodwork.testosterone == null)
                      Text('No results recorded yet',
                          style: AppTextStyles.bodyMedium),
                  ],
                  // Display notes if any
                  if (bloodwork.notes?.isNotEmpty == true) ...[
                    SharedWidgets.verticalSpace(),
                    Text(
                      'Notes: ${bloodwork.notes}',
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Build a card for an individual medication
  /// Updated to use MedicationDose model and new providers
  Widget _buildMedicationCard(Medication medication) {
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

            SharedWidgets.verticalSpace(16),

            // Medication details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => NavigationService.goToMedicationDetails(
                        context,
                        medication: medication),
                    child: Text(
                      medication.name,
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  SharedWidgets.verticalSpace(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display dosage
                      Text(
                        medication.dosage,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 4),

                      // Display times medication is taken
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...(() {
                            // Create a sorted copy of all time slots
                            final sortedTimes =
                                List<DateTime>.from(medication.timeOfDay);

                            // Sort all time slots
                            sortedTimes.sort((a, b) {
                              final aTimeStr =
                                  DateTimeFormatter.formatTimeToAMPM(
                                      TimeOfDay.fromDateTime(a));
                              final bTimeStr =
                                  DateTimeFormatter.formatTimeToAMPM(
                                      TimeOfDay.fromDateTime(b));
                              return DateTimeFormatter.compareTimeSlots(
                                  aTimeStr, bTimeStr);
                            });

                            // Convert each time slot to a UI element with checkmark if taken
                            return sortedTimes.map((time) {
                              // Format times consistently
                              final timeOfDay = TimeOfDay.fromDateTime(time);
                              final timeStr =
                                  DateTimeFormatter.formatTimeToAMPM(timeOfDay);

                              // Create a medication dose object instead of a string key
                              final dose = MedicationDose(
                                medicationId: medication.id,
                                date: _selectedDay,
                                timeSlot: timeStr,
                              );

                              // Use the new provider to check if taken
                              final isTaken =
                                  ref.watch(isDoseTakenProvider(dose));

                              return Padding(
                                padding: const EdgeInsets.only(left: 0, top: 2),
                                child: Row(
                                  children: [
                                    // Add time icon
                                    Icon(
                                      DateTimeFormatter.getTimeIcon(timeStr),
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    SharedWidgets.verticalSpace(),
                                    // Display formatted time
                                    Text(
                                      timeStr,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    // Show checkmark if taken
                                    if (isTaken)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(
                                          AppIcons.getIcon('success'),
                                          color: AppColors.tertiary,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList();
                          })(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// The rest of the file remains largely unchanged for now, but in a complete
// refactoring, we would move the injection date calculation functions to the
// MedicationScheduleService

//----------------------------------------------------------------------------
// MEDICATION CALENDAR COMPONENT
//----------------------------------------------------------------------------

/// Custom calendar widget showing medication schedules with visual indicators
class MedicationCalendar extends ConsumerWidget {
  final List<Medication> medications;
  final Function(DateTime) onDaySelected;

  const MedicationCalendar({
    Key? key,
    required this.medications,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MedicationCalendarView(
      medications: medications,
      onDaySelected: onDaySelected,
      ref: ref,
    );
  }
}

class _MedicationCalendarView extends StatefulWidget {
  final List<Medication> medications;
  final Function(DateTime) onDaySelected;
  final WidgetRef ref;

  const _MedicationCalendarView({
    Key? key,
    required this.medications,
    required this.onDaySelected,
    required this.ref,
  }) : super(key: key);

  @override
  _MedicationCalendarViewState createState() => _MedicationCalendarViewState();
}

class _MedicationCalendarViewState extends State<_MedicationCalendarView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Set<DateTime> _injectionDueDates;
  late Set<DateTime> _bloodworkDates;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _updateInjectionDates();
    _updateBloodworkDates();
  }

  @override
  void didUpdateWidget(_MedicationCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.medications != oldWidget.medications) {
      _updateInjectionDates();
      _updateBloodworkDates();
    }
  }

  /// Update the set of dates that have injections due
  void _updateInjectionDates() {
    _injectionDueDates = MedicationScheduleService.calculateInjectionDueDates(
        widget.medications);
  }

  /// Update the set of dates that have bloodwork recorded
  void _updateBloodworkDates() {
    _bloodworkDates = widget.ref.read(bloodworkDatesProvider);
  }

  /// Check if a date has an injection due
  bool _hasInjectionDue(DateTime date) {
    // Compare just the date part, not time
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _injectionDueDates.any((injectionDate) {
      final normalizedInjectionDate = DateTime(
        injectionDate.year,
        injectionDate.month,
        injectionDate.day,
      );
      return normalizedInjectionDate.isAtSameMomentAs(normalizedDate);
    });
  }

  /// Check if a date has bloodwork tests
  bool _hasBloodworkOnDate(DateTime date) {
    // Compare just the date part, not time
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _bloodworkDates.any((labDate) {
      final normalizedLabDate = DateTime(
        labDate.year,
        labDate.month,
        labDate.day,
      );
      return normalizedLabDate.isAtSameMomentAs(normalizedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.standardScreenMargins,
      child: TableCalendar(
        // Calendar configuration
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
          // Default builder for regular days
          defaultBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day);
            bool hasBloodwork = _hasBloodworkOnDate(day);

            // Check for bloodwork days
            if (hasBloodwork) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.bloodworkColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: AppTheme.bloodworkColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            // Check for injection days
            if (hasInjection) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppTheme.injectionDueColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: AppTheme.injectionDueColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            return null; // Use default rendering for other days
          },

          // Builder for selected days
          selectedBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day);
            bool hasBloodwork = _hasBloodworkOnDate(day);

            // Determine border color based on what's happening on this day
            Color borderColor = hasBloodwork
                ? AppTheme.bloodworkColor
                : (hasInjection
                    ? AppTheme.injectionDueColor
                    : Colors.transparent);
            bool hasBorder = hasInjection || hasBloodwork;

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Change the background color when selected day has special events
                color: hasBorder
                    ? (hasBloodwork
                        ? AppTheme.bloodworkColor
                        : AppTheme.injectionDueColor)
                    : AppColors.primary,
                border:
                    hasBorder ? Border.all(color: borderColor, width: 2) : null,
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

          // Builder for today
          todayBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day);
            bool hasBloodwork = _hasBloodworkOnDate(day);

            // Determine border color
            Color borderColor;
            if (hasBloodwork) {
              borderColor = AppTheme.bloodworkColor;
            } else if (hasInjection) {
              borderColor = AppTheme.injectionDueColor;
            } else {
              borderColor = AppColors.primary;
            }

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(40),
                border: Border.all(
                  color: borderColor,
                  width: hasBloodwork || hasInjection ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: hasBloodwork
                        ? AppTheme.bloodworkColor
                        : (hasInjection
                            ? AppTheme.injectionDueColor
                            : AppColors.primary),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },

          // Builder for days outside the current month
          outsideBuilder: (context, day, focusedDay) {
            bool hasInjection = _hasInjectionDue(day);
            bool hasBloodwork = _hasBloodworkOnDate(day);

            // Bloodwork outside current month
            if (hasBloodwork) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.bloodworkColor.withAlpha(160), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: AppTheme.bloodworkColor.withAlpha(160),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            // Injection outside current month
            if (hasInjection) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.injectionDueColor.withAlpha(160),
                      width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: AppTheme.injectionDueColor.withAlpha(160),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            // Regular days outside current month
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
}
