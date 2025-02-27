//
//  daily_tracker_screen.dart
//  Screen for tracking daily medications
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/models/medication_dose.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/features/medication_tracker/services/medication_schedule_service.dart';
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
              child: _MedicationsList(
                key: ValueKey<DateTime>(selectedDate),
                groupedMedications: groupedMedications,
                selectedDate: selectedDate,
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
            // Current date display
            Text(
              DateTimeFormatter.formatDateMMMDDYYYY(selectedDate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
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

/// List of medications grouped by time
class _MedicationsList extends ConsumerWidget {
  const _MedicationsList({
    super.key,
    required this.groupedMedications,
    required this.selectedDate,
  });

  final List<MedicationTimeGroup> groupedMedications;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show empty state if no medications are scheduled
    if (groupedMedications.isEmpty) {
      return Center(
        child: Text(
          'No medications scheduled for this day',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // Show grouped medications by time
    return ListView.builder(
      padding: AppTheme.standardCardPadding,
      itemCount: groupedMedications.length,
      itemBuilder: (context, index) => _TimeGroupItem(
        timeGroup: groupedMedications[index],
        selectedDate: selectedDate,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time slot header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
          child: Row(
            children: [
              Icon(DateTimeFormatter.getTimeIcon(timeGroup.timeSlot),
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(timeGroup.timeSlot, style: AppTextStyles.titleMedium),
            ],
          ),
        ),
        // Card containing medications for this time slot
        Card(
          child: Padding(
            padding: AppTheme.standardCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...timeGroup.medications.map(
                  (med) => _MedicationListTile(
                    medication: med,
                    timeSlot: timeGroup.timeSlot,
                    selectedDate: selectedDate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(right: 24.0), // push left
        child: Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: TextButton(
              style: TextButton.styleFrom(textStyle: AppTextStyles.titleMedium),
              child: Text(medication.name),
              onPressed: () => NavigationService.goToMedicationDetails(context,
                  medication: medication),
            ),
          ),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.dosage,
            style: AppTextStyles.bodyMedium,
          ),
          // Show quantity with warning color if refill needed
          if (medication.currentQuantity > 0 && medication.refillThreshold > 0)
            Text(
              'Remaining: ${medication.currentQuantity}',
              style: TextStyle(
                fontSize: AppTextStyles.bodyMedium.fontSize,
                fontWeight: AppTextStyles.bodyMedium.fontWeight,
                fontFamily: AppTextStyles.bodyMedium.fontFamily,
                color: medication.currentQuantity <= medication.refillThreshold
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkbox to mark medication as taken
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: isTaken,
              onChanged: (bool? value) => _handleTakenChange(value, ref, dose),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.tertiary;
                }
                return AppColors.surfaceContainer;
              }),
              checkColor: AppColors.onTertiary,
            ),
          ),
        ],
      ),
      // Subtle background color for taken medications
      tileColor: isTaken ? AppColors.tertiary.withAlpha(40) : null,
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

    // Normalize the date to prevent time-related issues
    final normalizedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

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

/// Data model for grouping medications by time slot
class MedicationTimeGroup {
  final String timeSlot;
  final List<Medication> medications;

  const MedicationTimeGroup({
    required this.timeSlot,
    List<Medication>? medications,
  }) : medications = medications ?? const [];
}
