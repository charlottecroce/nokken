import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_taken_provider.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';

// Provider to track the selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
// Provider to track slide direction
final slideDirectionProvider = StateProvider<bool>((ref) => true);

class DailyTrackerScreen extends ConsumerStatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  void _loadTakenMedicationsForCurrentDate() {
    final selectedDate = ref.read(selectedDateProvider);
    //print('Loading taken medications for date: ${selectedDate.toIso8601String()}');

    // Use normalized date
    final normalizedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    ref
        .read(medicationTakenProvider.notifier)
        .loadTakenMedicationsForDate(normalizedDate);
  }

  @override
  Widget build(BuildContext context) {
    final medications =
        ref.watch(medicationStateProvider.select((state) => state.medications));
    final selectedDate = ref.watch(selectedDateProvider);

    // When the date changes, load taken medications for the new date
    ref.listen(selectedDateProvider, (previous, next) {
      if (previous != next) {
        //print('Date changed from ${previous?.toIso8601String()} to ${next.toIso8601String()}');
        // Always use normalized date
        final normalizedDate = DateTime(next.year, next.month, next.day);
        ref
            .read(medicationTakenProvider.notifier)
            .loadTakenMedicationsForDate(normalizedDate);
      }
    });

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
          _DateSelector(selectedDate: selectedDate),
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

  static List<Medication> _getMedicationsForDay(
      List<Medication> medications, DateTime date) {
    if (medications.isEmpty) return const [];
    final weekday = DateConstants.orderedDays[date.weekday % 7];

    return medications
        .where((med) =>
            med.daysOfWeek.contains(weekday) &&
            !date.isBefore(DateTime(
                med.startDate.year, med.startDate.month, med.startDate.day)))
        .toList();
  }

  static List<MedicationTimeGroup> _groupMedicationsByTime(
      List<Medication> medications, BuildContext context) {
    if (medications.isEmpty) return const [];

    final groups = <String, List<Medication>>{};

    for (final med in medications) {
      for (final time in med.timeOfDay) {
        // Always use AM/PM format for time
        final timeStr =
            DateTimeFormatter.formatTimeToAMPM(TimeOfDay.fromDateTime(time));
        groups.putIfAbsent(timeStr, () => []).add(med);
      }
    }

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
            IconButton(
              icon: Icon(AppIcons.getIcon('chevron_left')),
              color: AppColors.onPrimary,
              onPressed: () => _changeDate(ref, -1),
            ),
            Text(
              DateTimeFormatter.formatDateMMMDDYYYY(selectedDate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimary,
                  ),
            ),
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

  void _changeDate(WidgetRef ref, int days) {
    ref.read(slideDirectionProvider.notifier).state = days > 0;
    ref.read(selectedDateProvider.notifier).update(
          (state) => state.add(Duration(days: days)),
        );
  }
}

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
    if (groupedMedications.isEmpty) {
      return Center(
        child: Text(
          'No medications scheduled for this day',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

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
    // Normalize the date to match how it's stored in the database (just year-month-day)
    final normalizedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final medicationKey =
        '${medication.id}-${normalizedDate.toIso8601String()}-$timeSlot';
    // Use the isMedicationTakenProvider to check if this medication is taken
    final isTaken = ref.watch(isMedicationTakenProvider(medicationKey));

    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(right: 24.0), // push left
        child: Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: TextButton(
              style: TextButton.styleFrom(textStyle: AppTextStyles.titleMedium),
              child: Text(medication.name),
              onPressed: () =>
                  NavigationService.showMedicaitonDetails(context, medication),
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
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: isTaken,
              onChanged: (bool? value) =>
                  _handleTakenChange(value, medicationKey, ref),
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
      tileColor: isTaken ? AppColors.surfaceContainer.withAlpha(40) : null,
    );
  }

  void _handleTakenChange(bool? value, String medicationKey, WidgetRef ref) {
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
          medication.id,
          normalizedDate,
          timeSlot,
          value,
        );

    // Update medication quantity
    ref
        .read(medicationStateProvider.notifier)
        .updateMedicationQuantity(medication, value);
  }
}

class MedicationTimeGroup {
  final String timeSlot;
  final List<Medication> medications;

  const MedicationTimeGroup({
    required this.timeSlot,
    List<Medication>? medications,
  }) : medications = medications ?? const [];
}
