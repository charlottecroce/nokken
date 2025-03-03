//
//  calendar_screen.dart
//  Monthly calendar view with medication schedule visualization
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/core/theme/shared_widgets.dart';
import 'package:nokken/src/core/utils/date_time_formatter.dart';
import 'package:nokken/src/core/utils/get_icons_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/features/medication_tracker/services/medication_schedule_service.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/core/services/database/database_service.dart';
import 'package:nokken/src/core/services/navigation/navigation_service.dart';
import 'package:nokken/src/core/theme/app_icons.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/app_colors.dart';
import 'package:nokken/src/core/theme/app_text_styles.dart';
import 'package:nokken/src/core/utils/get_labels.dart';

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

      // Sort medications by their first time slot
      final sortedMedications = _sortMedicationsByTime(medications);

      // Update state with fetched medications
      setState(() {
        _medications = sortedMedications;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors that might occur during database operations
      //print('Error loading medications: $e');

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

  /// Sort medications by their first time slot
  List<Medication> _sortMedicationsByTime(List<Medication> medications) {
    final sortedMeds = [...medications];

    sortedMeds.sort((a, b) {
      if (a.timeOfDay.isEmpty) return 1;
      if (b.timeOfDay.isEmpty) return -1;

      final aTime = a.timeOfDay.first;
      final bTime = b.timeOfDay.first;

      return (aTime.hour * 60 + aTime.minute) -
          (bTime.hour * 60 + bTime.minute);
    });

    return sortedMeds;
  }

  /// Filter medications to those that should appear on the selected day
  /// Now using the MedicationScheduleService
  List<Medication> _getMedicationsForSelectedDay() {
    final medicationsForDay = MedicationScheduleService.getMedicationsForDate(
        _medications, _selectedDay);

    // Sort medications by time
    return _sortMedicationsByTime(medicationsForDay);
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

    // Format the appointment time
    final timeOfDay = TimeOfDay.fromDateTime(bloodwork.date);
    final timeStr = DateTimeFormatter.formatTimeToAMPM(timeOfDay);
    final timeIcon = DateTimeFormatter.getTimeIcon(timeStr);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment type icon
            GetIconsColors.getAppointmentIconWithColor(
                bloodwork.appointmentType),

            SharedWidgets.verticalSpace(AppTheme.doubleSpacing),

            // Appointment details
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
                          GetLabels.getAppointmentTypeText(
                              bloodwork.appointmentType),
                          style: AppTextStyles.titleLarge,
                        ),
                        if (isDateInFuture) ...[
                          SharedWidgets.horizontalSpace(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.info.withAlpha(60)),
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

                  // Display appointment time with appropriate icon
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          timeIcon,
                          size: 16,
                          color: GetIconsColors.getAppointmentColor(
                              bloodwork.appointmentType),
                        ),
                        SharedWidgets.verticalSpace(6),
                        Text(
                          timeStr,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: GetIconsColors.getAppointmentColor(
                                bloodwork.appointmentType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Display location if available
                  if (bloodwork.location?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          AppIcons.getOutlined('location'),
                          size: 16,
                          color: Colors.grey,
                        ),
                        SharedWidgets.verticalSpace(6),
                        Text(
                          bloodwork.location!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    SharedWidgets.verticalSpace(2),
                  ],

                  // Display doctor if available
                  if (bloodwork.doctor?.isNotEmpty == true) ...[
                    Row(
                      children: [
                        Icon(
                          AppIcons.getIcon('profile'),
                          size: 16,
                          color: Colors.grey,
                        ),
                        SharedWidgets.verticalSpace(6),
                        Text(
                          bloodwork.doctor!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    SharedWidgets.verticalSpace(2),
                  ],

                  // If future date, show scheduled message
                  if (isDateInFuture)
                    Text(
                      'Appointment scheduled',
                      style: AppTextStyles.bodyMedium,
                    )
                  // Otherwise show hormone levels if bloodwork type
                  else if (bloodwork.appointmentType ==
                      AppointmentType.bloodwork) ...[
                    // Display hormone readings if available
                    if (bloodwork.hormoneReadings.isNotEmpty)
                      ...bloodwork.hormoneReadings.take(2).map((reading) => Text(
                          '${reading.name}: ${reading.value.toStringAsFixed(1)} ${reading.unit}',
                          overflow: TextOverflow.ellipsis)), // Added ellipsis

                    // Show count if there are more readings
                    if (bloodwork.hormoneReadings.length > 2)
                      Text(
                          '...and ${bloodwork.hormoneReadings.length - 2} more',
                          style: AppTextStyles.bodySmall),

                    // For backward compatibility
                    if (bloodwork.hormoneReadings.isEmpty) ...[
                      if (bloodwork.estrogen != null)
                        Text(
                            'Estrogen: ${bloodwork.estrogen!.toStringAsFixed(1)} pg/mL',
                            overflow: TextOverflow.ellipsis), // Added ellipsis
                      if (bloodwork.testosterone != null)
                        Text(
                            'Testosterone: ${bloodwork.testosterone!.toStringAsFixed(1)} ng/dL',
                            overflow: TextOverflow.ellipsis), // Added ellipsis
                    ],
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
            GetIconsColors.getMedicationIconWithColor(
                medication.medicationType),

            SharedWidgets.verticalSpace(AppTheme.doubleSpacing),

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
                      SharedWidgets.verticalSpace(4),

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
                                      color: GetIconsColors.getMedicationColor(
                                          medication.medicationType),
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
    super.key,
    required this.medications,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MedicationCalendarView(
      medications: medications,
      onDaySelected: onDaySelected,
      ref: ref,
    );
  }
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

  /// Get the appointment type for a given date
  AppointmentType? _getAppointmentTypeForDate(DateTime date) {
    // Normalize date for comparison
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Get bloodwork records for this date
    final bloodworkRecords =
        widget.ref.read(bloodworkRecordsProvider).where((record) {
      final recordDate =
          DateTime(record.date.year, record.date.month, record.date.day);
      return recordDate.isAtSameMomentAs(normalizedDate);
    }).toList();

    // Prioritize by appointment type (surgery > appointment > bloodwork)
    if (bloodworkRecords.isNotEmpty) {
      if (bloodworkRecords
          .any((r) => r.appointmentType == AppointmentType.surgery)) {
        return AppointmentType.surgery;
      } else if (bloodworkRecords
          .any((r) => r.appointmentType == AppointmentType.appointment)) {
        return AppointmentType.appointment;
      } else {
        return AppointmentType.bloodwork;
      }
    }
    return null;
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

            // Check for appointment days and get the appropriate color
            if (hasBloodwork) {
              final appointmentType = _getAppointmentTypeForDate(day);
              final appointmentColor = appointmentType != null
                  ? GetIconsColors.getAppointmentColor(appointmentType)
                  : AppColors.primary;

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: appointmentColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: appointmentColor,
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
                  border: Border.all(color: AppColors.injection, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: AppColors.injection,
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
            AppointmentType? appointmentType;
            Color borderColor;

            if (hasBloodwork) {
              appointmentType = _getAppointmentTypeForDate(day);
              borderColor = appointmentType != null
                  ? GetIconsColors.getAppointmentColor(appointmentType)
                  : AppColors.primary;
            } else if (hasInjection) {
              borderColor = AppColors.injection;
            } else {
              borderColor = Colors.transparent;
            }

            bool hasBorder = hasInjection || hasBloodwork;

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Change the background color when selected day has special events
                color: hasBorder
                    ? (hasBloodwork
                        ? appointmentType != null
                            ? GetIconsColors.getAppointmentColor(
                                appointmentType)
                            : AppColors.primary
                        : AppColors.injection)
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
            Color borderColor;

            if (hasBloodwork) {
              final appointmentType = _getAppointmentTypeForDate(day);
              borderColor = appointmentType != null
                  ? GetIconsColors.getAppointmentColor(appointmentType)
                  : AppColors.primary;
            } else if (hasInjection) {
              borderColor = AppColors.injection;
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
                        ? borderColor
                        : (hasInjection
                            ? AppColors.injection
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
            Color borderColor;

            if (hasBloodwork) {
              final appointmentType = _getAppointmentTypeForDate(day);
              borderColor = appointmentType != null
                  ? GetIconsColors.getAppointmentColor(appointmentType)
                      .withAlpha(160)
                  : AppColors.primary.withAlpha(160);

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: borderColor,
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
                      color: AppColors.injection.withAlpha(160), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: AppColors.injection.withAlpha(160),
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

class _MedicationCalendarView extends StatefulWidget {
  final List<Medication> medications;
  final Function(DateTime) onDaySelected;
  final WidgetRef ref;

  const _MedicationCalendarView({
    required this.medications,
    required this.onDaySelected,
    required this.ref,
  });

  @override
  _MedicationCalendarViewState createState() => _MedicationCalendarViewState();
}
