//
//  daily_tracker_screen.dart
//  Screen for tracking daily medications and appointments
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/features/medication_tracker/services/medication_schedule_service.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';
import 'package:nokken/src/shared/utils/appointment_utils.dart';

/// Provider to track the currently selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Provider to track slide direction for day-change animation
final slideDirectionProvider = StateProvider<bool>((ref) => true);

/// Provider for bloodwork records on selected date
final bloodworkForSelectedDateProvider =
    Provider.family<List<Bloodwork>, DateTime>((ref, date) {
  final bloodworkRecords = ref.watch(bloodworkRecordsProvider);
  return bloodworkRecords.where((record) {
    // Compare just the date part (not time)
    final recordDate =
        DateTime(record.date.year, record.date.month, record.date.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    return recordDate.isAtSameMomentAs(selectedDate);
  }).toList();
});

/// Provider to get unique medication doses with index
final uniqueMedicationDosesProvider =
    Provider.family<List<(MedicationDose, int, Medication)>, DateTime>(
        (ref, date) {
  final medications = ref.watch(medicationsForDateProvider(date));
  final result = <(MedicationDose, int, Medication)>[];

  for (final med in medications) {
    // Group by time slot
    final Map<String, List<DateTime>> timeSlots = {};

    for (final time in med.timeOfDay) {
      final timeSlot =
          DateTimeFormatter.formatTimeToAMPM(TimeOfDay.fromDateTime(time));

      if (!timeSlots.containsKey(timeSlot)) {
        timeSlots[timeSlot] = [];
      }

      timeSlots[timeSlot]!.add(time);
    }

    // Create doses with indexes for each time slot
    for (final entry in timeSlots.entries) {
      final timeSlot = entry.key;
      final times = entry.value;

      for (int i = 0; i < times.length; i++) {
        final dose = MedicationDose(
          medicationId: med.id,
          date: date,
          timeSlot: timeSlot,
        );

        result.add((dose, i, med));
      }
    }
  }

  // Sort by time slot
  result.sort((a, b) {
    final timeA = DateTimeFormatter.parseTimeString(a.$1.timeSlot);
    final timeB = DateTimeFormatter.parseTimeString(b.$1.timeSlot);
    return (timeA.hour * 60 + timeA.minute) - (timeB.hour * 60 + timeB.minute);
  });

  return result;
});

/// Provider to check if a specific medication dose with index is taken
final isUniqueDoseTakenProvider =
    Provider.family<bool, (MedicationDose, int)>((ref, params) {
  final takenMedications = ref.watch(medicationTakenProvider);
  final dose = params.$1;
  final index = params.$2;

  final key =
      '${dose.medicationId}-${dose.date.toIso8601String()}-${dose.timeSlot}-$index';

  // First check for the indexed key
  if (takenMedications.contains(key)) {
    return true;
  }

  // For backward compatibility, check if old-style key exists and it's the first instance (index 0)
  if (index == 0 && takenMedications.contains(dose.toKey())) {
    return true;
  }

  return false;
});

class DailyTrackerScreen extends ConsumerStatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  _DailyTrackerScreenState createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load taken medications for the current date
    _loadTakenMedicationsForCurrentDate();
  }

  /// Loads which medications have been taken for the current date
  void _loadTakenMedicationsForCurrentDate() {
    final selectedDate = ref.read(selectedDateProvider);

    // Use normalized date (no time component)
    final normalizedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    ref
        .read(medicationTakenProvider.notifier)
        .loadTakenMedicationsForDate(normalizedDate);
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to medication data
    final medications =
        ref.watch(medicationStateProvider.select((state) => state.medications));
    final selectedDate = ref.watch(selectedDateProvider);

    // Get bloodwork records for the selected date
    final bloodworkRecords =
        ref.watch(bloodworkForSelectedDateProvider(selectedDate));

    // Listen for date changes to reload taken medications
    ref.listen(selectedDateProvider, (previous, next) {
      if (previous != next) {
        // Always use normalized date
        final normalizedDate = DateTime(next.year, next.month, next.day);
        ref
            .read(medicationTakenProvider.notifier)
            .loadTakenMedicationsForDate(normalizedDate);
      }
    });

    // Get unique medication doses for this day
    final uniqueDoses = ref.watch(uniqueMedicationDosesProvider(selectedDate));

    // Group unique doses by time slot
    final Map<String, List<(MedicationDose, int, Medication)>> groupedDoses =
        {};

    for (final doseWithIndex in uniqueDoses) {
      final timeSlot = doseWithIndex.$1.timeSlot;
      if (!groupedDoses.containsKey(timeSlot)) {
        groupedDoses[timeSlot] = [];
      }
      groupedDoses[timeSlot]!.add(doseWithIndex);
    }

    // Get all time slots sorted
    final sortedTimeSlots = groupedDoses.keys.toList()
      ..sort((a, b) => DateTimeFormatter.compareTimeSlots(a, b));

    // Create time groups from the sorted doses
    final List<MedicationTimeGroup> timeGroups = [];

    for (final timeSlot in sortedTimeSlots) {
      final dosesForTimeSlot = groupedDoses[timeSlot]!;
      final medications = dosesForTimeSlot.map((e) => e.$3).toList();
      timeGroups.add(MedicationTimeGroup(
        timeSlot: timeSlot,
        medications: medications,
        doseIndexes: dosesForTimeSlot.map((e) => (e.$1, e.$2)).toList(),
      ));
    }

    // Create a merged content model for the day (medications + appointments)
    final bool hasContent =
        timeGroups.isNotEmpty || bloodworkRecords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        leading: IconButton(
            onPressed: () => NavigationService.goToCalendar(context).then((_) {
                  _loadTakenMedicationsForCurrentDate();
                }),
            icon: Icon(AppIcons.getIcon('calendar'))),
      ),
      body: Column(
        children: [
          // Date selector component
          _DateSelector(selectedDate: selectedDate),

          // Medications list with animation for date changes
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                bool isForward = ref.watch(slideDirectionProvider);
                if (child.key == ValueKey<DateTime>(selectedDate)) {
                  // Entering widget
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(isForward ? 1.0 : -1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                } else {
                  // Exiting widget
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(isForward ? -1.0 : 1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                }
              },
              child: _DailyScheduleList(
                key: ValueKey<DateTime>(selectedDate),
                timeGroups: timeGroups,
                bloodworkRecords: bloodworkRecords,
                selectedDate: selectedDate,
                hasContent: hasContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date selector component for navigating between days
class _DateSelector extends ConsumerWidget {
  const _DateSelector({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.primary,
      margin: null,
      child: Padding(
        padding: AppTheme.standardCardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous day button
            IconButton(
              icon: Icon(AppIcons.getIcon('chevron_left')),
              color: AppColors.onPrimary,
              onPressed: () => _changeDate(ref, -1),
            ),
            // Current date display - wrapped in Flexible
            Flexible(
              child: Text(
                DateTimeFormatter.formatDateMMMDDYYYY(selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                    ),
                textAlign: TextAlign.center, // Center the text
                overflow: TextOverflow
                    .ellipsis, // Add ellipsis if text is too long. not ideal but prevents errors
              ),
            ),
            // Next day button
            IconButton(
              icon: Icon(AppIcons.getIcon('chevron_right')),
              color: AppColors.onPrimary,
              onPressed: () => _changeDate(ref, 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Change the date by the specified number of days (-1, 1)
  void _changeDate(WidgetRef ref, int days) {
    // Update slide direction for animation
    ref.read(slideDirectionProvider.notifier).state = days > 0;

    // Update selected date
    ref.read(selectedDateProvider.notifier).update(
          (state) => state.add(Duration(days: days)),
        );
  }
}

/// Daily schedule list showing both medications and appointments
class _DailyScheduleList extends ConsumerWidget {
  const _DailyScheduleList({
    super.key,
    required this.timeGroups,
    required this.bloodworkRecords,
    required this.selectedDate,
    required this.hasContent,
  });

  final List<MedicationTimeGroup> timeGroups;
  final List<Bloodwork> bloodworkRecords;
  final DateTime selectedDate;
  final bool hasContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show empty state if no content is scheduled
    if (!hasContent) {
      return Center(
        child: Text(
          'No medications or appointments scheduled for this day',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // Combine medications and appointments into a chronologically sorted list
    final sortedItems = _getSortedScheduleItems();

    // Show the sorted schedule
    return ListView.builder(
      padding: AppTheme.standardCardPadding,
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];

        if (item is _AppointmentItem) {
          return _buildAppointmentSection(item.bloodwork);
        } else if (item is _MedicationGroupItem) {
          return _TimeGroupItem(
            timeGroup: item.timeGroup,
            selectedDate: selectedDate,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Builds the appointment section UI
  Widget _buildAppointmentSection(Bloodwork bloodwork) {
    // Format the appointment time
    final timeOfDay = TimeOfDay.fromDateTime(bloodwork.date);
    final timeStr = DateTimeFormatter.formatTimeToAMPM(timeOfDay);

    // Use the AppointmentUtils to get the appointment color
    final appointmentColor =
        AppointmentUtils.getAppointmentTypeColor(bloodwork.appointmentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment time header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
          child: Row(
            children: [
              Icon(DateTimeFormatter.getTimeIcon(timeStr),
                  size: 20, color: appointmentColor),
              const SizedBox(width: 8),
              Text(timeStr,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: appointmentColor)),
            ],
          ),
        ),
        // Appointment card
        _AppointmentCard(bloodwork: bloodwork),
      ],
    );
  }

  /// Sorts schedule items chronologically
  List<_ScheduleItem> _getSortedScheduleItems() {
    final List<_ScheduleItem> items = [];

    // Add medication groups
    for (final group in timeGroups) {
      items.add(_MedicationGroupItem(timeGroup: group));
    }

    // Add bloodwork appointments
    for (final bloodwork in bloodworkRecords) {
      items.add(_AppointmentItem(bloodwork: bloodwork));
    }

    // Sort by time
    items.sort((a, b) {
      final timeA = a is _MedicationGroupItem
          ? DateTimeFormatter.parseTimeString(a.timeGroup.timeSlot)
          : TimeOfDay.fromDateTime((a as _AppointmentItem).bloodwork.date);

      final timeB = b is _MedicationGroupItem
          ? DateTimeFormatter.parseTimeString(b.timeGroup.timeSlot)
          : TimeOfDay.fromDateTime((b as _AppointmentItem).bloodwork.date);

      return (timeA.hour * 60 + timeA.minute) -
          (timeB.hour * 60 + timeB.minute);
    });

    return items;
  }
}

/// Card displaying a medical appointment
class _AppointmentCard extends StatelessWidget {
  final Bloodwork bloodwork;

  const _AppointmentCard({required this.bloodwork});

  @override
  Widget build(BuildContext context) {
    final isDateInFuture = DateTime(
      bloodwork.date.year,
      bloodwork.date.month,
      bloodwork.date.day,
    ).isAfter(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    // Get appointment specific details using AppointmentUtils
    final appointmentTitle =
        AppointmentUtils.getAppointmentTypeText(bloodwork.appointmentType);
    final appointmentIcon =
        AppointmentUtils.getAppointmentTypeIcon(bloodwork.appointmentType);
    final appointmentColor =
        AppointmentUtils.getAppointmentTypeColor(bloodwork.appointmentType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment type icon
            Icon(appointmentIcon, color: appointmentColor),

            SharedWidgets.verticalSpace(16),

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
                          appointmentTitle,
                          style: AppTextStyles.titleLarge,
                        ),
                        if (isDateInFuture) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.info.withAlpha(50)),
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

                  // Display location if available
                  if (bloodwork.location?.isNotEmpty == true) ...[
                    SharedWidgets.verticalSpace(8),
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
                  ],

                  // Display doctor if available
                  if (bloodwork.doctor?.isNotEmpty == true) ...[
                    SharedWidgets.verticalSpace(4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outlined,
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
                  ],

                  // Display notes if any
                  if (bloodwork.notes?.isNotEmpty == true) ...[
                    SharedWidgets.verticalSpace(8),
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
}

/// Group of medications scheduled for the same time
class _TimeGroupItem extends StatelessWidget {
  const _TimeGroupItem({
    required this.timeGroup,
    required this.selectedDate,
  });

  final MedicationTimeGroup timeGroup;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    // Determine the group color based on medication types
    Color timeGroupColor = _getTimeGroupColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time slot header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
          child: Row(
            children: [
              Icon(DateTimeFormatter.getTimeIcon(timeGroup.timeSlot),
                  size: 20, color: timeGroupColor),
              const SizedBox(width: 8),
              Text(
                timeGroup.timeSlot,
                style:
                    AppTextStyles.titleMedium.copyWith(color: timeGroupColor),
              ),
            ],
          ),
        ),
        // List of medications for this time slot (now each med is its own card)
        Column(
          children: List.generate(timeGroup.doseIndexes.length, (i) {
            final doseWithIndex = timeGroup.doseIndexes[i];
            final medication = timeGroup.medications[i];
            return _MedicationListTile(
              medication: medication,
              dose: doseWithIndex.$1,
              doseIndex: doseWithIndex.$2,
              selectedDate: selectedDate,
            );
          }),
        ),
      ],
    );
  }

  /// Determine color based on the types of medications in this group
  Color _getTimeGroupColor() {
    bool hasOral = false;
    bool hasInjection = false;

    for (final med in timeGroup.medications) {
      if (med.medicationType == MedicationType.oral) {
        hasOral = true;
      } else if (med.medicationType == MedicationType.injection) {
        hasInjection = true;
      }
    }

    // If there's a mix of types, use white (or a neutral color)
    if (hasOral && hasInjection) {
      return Colors.grey;
    }
    // Otherwise, use the specific type color
    else if (hasOral) {
      return AppColors.oralMedication;
    } else if (hasInjection) {
      return AppColors.injection;
    }

    // Default fallback color
    return AppColors.primary;
  }
}

/// Individual medication item with take/untake functionality
class _MedicationListTile extends ConsumerWidget {
  const _MedicationListTile({
    required this.medication,
    required this.dose,
    required this.doseIndex,
    required this.selectedDate,
  });

  final Medication medication;
  final MedicationDose dose;
  final int doseIndex;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this specific instance is taken using the new provider
    final isTaken = ref.watch(isUniqueDoseTakenProvider((dose, doseIndex)));

    // Determine icon and color based on medication type
    final IconData medicationIcon =
        medication.medicationType == MedicationType.oral
            ? AppIcons.getOutlined('medication')
            : AppIcons.getOutlined('vaccine');

    // Set color based on medication type
    final Color medicationColor =
        medication.medicationType == MedicationType.oral
            ? AppColors.oralMedication
            : AppColors.injection;

    // Add dose index indicator if this is not the first dose at this time
    final String doseIndicator =
        doseIndex > 0 ? ' (Dose ${doseIndex + 1})' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication type icon
              Icon(medicationIcon, color: medicationColor),

              SharedWidgets.verticalSpace(16),

              // Medication details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication name with link
                    InkWell(
                      onTap: () => NavigationService.goToMedicationDetails(
                        context,
                        medication: medication,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              medication.name + doseIndicator,
                              style: AppTextStyles.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Show refill indicator if needed
                          if (medication.needsRefill()) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.error.withAlpha(50)),
                              ),
                              child: Text(
                                'Refill Needed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Medication dosage
                    SharedWidgets.verticalSpace(8),
                    Text(
                      medication.dosage,
                      style: AppTextStyles.bodyMedium,
                    ),

                    // Show quantity with warning color if refill needed
                    if (medication.currentQuantity > 0) ...[
                      SharedWidgets.verticalSpace(4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: medication.needsRefill()
                                ? AppColors.error
                                : Colors.grey,
                          ),
                          SharedWidgets.verticalSpace(6),
                          Text(
                            'Remaining: ${medication.currentQuantity}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: medication.needsRefill()
                                  ? AppColors.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Show taken status
                    SharedWidgets.verticalSpace(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status text
                        Text(
                          isTaken ? 'Taken' : 'Not taken',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isTaken ? AppColors.tertiary : Colors.grey,
                          ),
                        ),

                        // Checkbox to mark medication as taken
                        Checkbox(
                          value: isTaken,
                          onChanged: (bool? value) =>
                              _handleTakenChange(value, ref),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.tertiary;
                            }
                            return AppColors.surfaceContainer;
                          }),
                          checkColor: AppColors.onTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle toggling a medication's taken status
  void _handleTakenChange(bool? value, WidgetRef ref) {
    if (value == null) return;

    // Check if we have enough quantity to mark as taken
    if (value &&
        medication.currentQuantity <= 0 &&
        medication.refillThreshold > 0) {
      // Show error message
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: const Text('Not enough medication remaining'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Create a key that includes the dose index
    final key =
        '${dose.medicationId}-${dose.date.toIso8601String()}-${dose.timeSlot}-$doseIndex';

    // Update taken medications in database and state
    // For the existing database schema, we'll still use the setMedicationTaken method
    // but internally we'll save using the unique key
    ref.read(medicationTakenProvider.notifier).setMedicationTaken(
          dose,
          value,
          customKey: key,
        );

    // Update medication quantity
    ref
        .read(medicationStateProvider.notifier)
        .updateMedicationQuantity(medication, value);
  }
}

/// Base class for schedule items
abstract class _ScheduleItem {}

/// A medication group item
class _MedicationGroupItem extends _ScheduleItem {
  final MedicationTimeGroup timeGroup;

  _MedicationGroupItem({required this.timeGroup});
}

/// An appointment item
class _AppointmentItem extends _ScheduleItem {
  final Bloodwork bloodwork;

  _AppointmentItem({required this.bloodwork});
}

/// Data model for grouping medications by time slot
class MedicationTimeGroup {
  final String timeSlot;
  final List<Medication> medications;
  final List<(MedicationDose, int)> doseIndexes;

  const MedicationTimeGroup({
    required this.timeSlot,
    List<Medication>? medications,
    List<(MedicationDose, int)>? doseIndexes,
  })  : medications = medications ?? const [],
        doseIndexes = doseIndexes ?? const [];
}
