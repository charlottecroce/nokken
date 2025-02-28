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

    // Get medications for the selected day, grouped by time
    final medicationsForDay = _getMedicationsForDay(medications, selectedDate);
    final groupedMedications =
        _groupMedicationsByTime(medicationsForDay, context);

    // Create a merged content model for the day (medications + appointments)
    final bool hasContent =
        groupedMedications.isNotEmpty || bloodworkRecords.isNotEmpty;

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
                groupedMedications: groupedMedications,
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

  /// Filters medications to only those scheduled for the given day
  static List<Medication> _getMedicationsForDay(
      List<Medication> medications, DateTime date) {
    if (medications.isEmpty) return const [];

    // Use the MedicationScheduleService which now uses the model's isDueOnDate method
    return MedicationScheduleService.getMedicationsForDate(medications, date);
  }

  /// Groups medications by time slot for organized display
  static List<MedicationTimeGroup> _groupMedicationsByTime(
      List<Medication> medications, BuildContext context) {
    if (medications.isEmpty) return const [];

    final groups = <String, List<Medication>>{};

    // Group medications by time slot
    for (final med in medications) {
      for (final time in med.timeOfDay) {
        // Always use AM/PM format for time
        final timeStr =
            DateTimeFormatter.formatTimeToAMPM(TimeOfDay.fromDateTime(time));
        groups.putIfAbsent(timeStr, () => []).add(med);
      }
    }

    // Convert to list of MedicationTimeGroup objects and sort by time
    return groups.entries
        .map((e) => MedicationTimeGroup(
              timeSlot: e.key,
              medications: e.value,
            ))
        .toList()
      ..sort(
          (a, b) => DateTimeFormatter.compareTimeSlots(a.timeSlot, b.timeSlot));
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
    required this.groupedMedications,
    required this.bloodworkRecords,
    required this.selectedDate,
    required this.hasContent,
  });

  final List<MedicationTimeGroup> groupedMedications;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment time header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
          child: Row(
            children: [
              Icon(DateTimeFormatter.getTimeIcon(timeStr),
                  size: 20,
                  color: _getAppointmentColor(bloodwork.appointmentType)),
              const SizedBox(width: 8),
              Text(timeStr,
                  style: AppTextStyles.titleMedium.copyWith(
                      color: _getAppointmentColor(bloodwork.appointmentType))),
            ],
          ),
        ),
        // Appointment card
        _AppointmentCard(bloodwork: bloodwork),
      ],
    );
  }

  /// Returns a color based on the appointment type
  Color _getAppointmentColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.bloodwork:
        return AppTheme.bloodworkColor;
      case AppointmentType.appointment:
        return AppTheme.doctorApptColor;
      case AppointmentType.surgery:
        return AppTheme.surgeryColor;
      default:
        return Colors.grey;
    }
  }

  /// Sorts schedule items chronologically
  List<_ScheduleItem> _getSortedScheduleItems() {
    final List<_ScheduleItem> items = [];

    // Add medication groups
    for (final group in groupedMedications) {
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

    // Get appointment specific details
    final String appointmentTitle;
    final IconData appointmentIcon;
    final Color appointmentColor;

    switch (bloodwork.appointmentType) {
      case AppointmentType.bloodwork:
        appointmentTitle = 'Lab Appointment';
        appointmentIcon = Icons.science_outlined;
        appointmentColor = AppTheme.bloodworkColor;
        break;
      case AppointmentType.appointment:
        appointmentTitle = 'Doctor Appointment';
        appointmentIcon = Icons.medical_services_outlined;
        appointmentColor = AppTheme.doctorApptColor;
        break;
      case AppointmentType.surgery:
        appointmentTitle = 'Surgery';
        appointmentIcon = Icons.medical_information_outlined;
        appointmentColor = AppTheme.surgeryColor;
        break;
      default:
        appointmentTitle = 'Medical Appointment';
        appointmentIcon = Icons.event_note_outlined;
        appointmentColor = Colors.grey;
    }

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
                          Icons.location_on_outlined,
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
          children: timeGroup.medications
              .map(
                (med) => _MedicationListTile(
                  medication: med,
                  timeSlot: timeGroup.timeSlot,
                  selectedDate: selectedDate,
                ),
              )
              .toList(),
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
      return AppTheme.oralMedColor;
    } else if (hasInjection) {
      return AppTheme.injectionColor;
    }

    // Default fallback color
    return AppColors.primary;
  }
}

/// Individual medication item with take/untake functionality
class _MedicationListTile extends ConsumerWidget {
  const _MedicationListTile({
    required this.medication,
    required this.timeSlot,
    required this.selectedDate,
  });

  final Medication medication;
  final String timeSlot;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dose = MedicationDose(
      medicationId: medication.id,
      date: selectedDate,
      timeSlot: timeSlot,
    );
    // Check if this medication is taken
    final isTaken = ref.watch(isDoseTakenProvider(dose));

    // Determine icon and color based on medication type
    final IconData medicationIcon =
        medication.medicationType == MedicationType.oral
            ? AppIcons.getOutlined('medication')
            : AppIcons.getOutlined('vaccine');

    // Set color based on medication type
    final Color medicationColor =
        medication.medicationType == MedicationType.oral
            ? AppTheme.oralMedColor
            : AppTheme.injectionColor;

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
                          Text(
                            medication.name,
                            style: AppTextStyles.titleLarge,
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
                              _handleTakenChange(value, ref, dose),
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
  void _handleTakenChange(bool? value, WidgetRef ref, MedicationDose dose) {
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

    // Update taken medications in database and state
    ref.read(medicationTakenProvider.notifier).setMedicationTaken(
          dose,
          value,
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

  const MedicationTimeGroup({
    required this.timeSlot,
    List<Medication>? medications,
  }) : medications = medications ?? const [];
}
