//
//  daily_tracker_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';

// Provider to track taken medications for the current day
final takenMedicationsProvider = StateProvider<Set<String>>((ref) => {});
// Provider to track the selected date
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
// Provider to track slide direction
final slideDirectionProvider = StateProvider<bool>((ref) => true);

class DailyTrackerScreen extends ConsumerStatefulWidget {
  final DateTime? selectedDate_FromMonthView;

  const DailyTrackerScreen({super.key, this.selectedDate_FromMonthView});

  @override
  // ignore: library_private_types_in_public_api
  _DailyTrackerScreenState createState() =>
      _DailyTrackerScreenState(); // Changed return type
}

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.selectedDate_FromMonthView != null) {
      Future.microtask(() {
        ref.read(selectedDateProvider.notifier).state =
            widget.selectedDate_FromMonthView!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medications =
        ref.watch(medicationStateProvider.select((state) => state.medications));
    final takenMedications = ref.watch(takenMedicationsProvider);

    final selectedDate = ref.watch(selectedDateProvider);

    final medicationsForDay = _getMedicationsForDay(medications, selectedDate);
    final groupedMedications =
        _groupMedicationsByTime(medicationsForDay, context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        leading: IconButton(
            onPressed: () => NavigationService.goToCalendar(context),
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
                takenMedications: takenMedications,
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
        final timeStr = TimeOfDay.fromDateTime(time).format(context);
        groups.putIfAbsent(timeStr, () => []).add(med);
      }
    }

    return groups.entries
        .map((e) => MedicationTimeGroup(
              timeSlot: e.key,
              medications: e.value,
            ))
        .toList()
      ..sort((a, b) => _compareTimeSlots(a.timeSlot, b.timeSlot));
  }

  static int _compareTimeSlots(String a, String b) {
    final timeA = _parseTimeString(a);
    final timeB = _parseTimeString(b);
    return timeA.hour * 60 + timeA.minute - (timeB.hour * 60 + timeB.minute);
  }

  static TimeOfDay _parseTimeString(String timeStr) {
    final isPM = timeStr.toLowerCase().contains('pm');
    final cleanTime =
        timeStr.toLowerCase().replaceAll(RegExp(r'[ap]m'), '').trim();

    final parts = cleanTime.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 0, minute: 0);

    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
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
              DateConstants.formatDate(selectedDate),
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
    required this.takenMedications,
    required this.selectedDate,
  });

  final List<MedicationTimeGroup> groupedMedications;
  final Set<String> takenMedications;
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
        takenMedications: takenMedications,
        selectedDate: selectedDate,
      ),
    );
  }
}

class _TimeGroupItem extends StatelessWidget {
  const _TimeGroupItem({
    required this.timeGroup,
    required this.takenMedications,
    required this.selectedDate,
  });

  final MedicationTimeGroup timeGroup;
  final Set<String> takenMedications;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing),
          child: Text(timeGroup.timeSlot, style: AppTextStyles.titleMedium),
        ),
        Card(
          child: Padding(
            padding: AppTheme.standardCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...timeGroup.medications
                    .map(
                      (med) => _MedicationListTile(
                        medication: med,
                        timeSlot: timeGroup.timeSlot,
                        takenMedications: takenMedications,
                        selectedDate: selectedDate,
                      ),
                    )
                    .toList(),
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
    required this.takenMedications,
    required this.selectedDate,
  });

  final Medication medication;
  final String timeSlot;
  final Set<String> takenMedications;
  final DateTime selectedDate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationKey =
        '${medication.id}-${selectedDate.toIso8601String()}-$timeSlot';
    final isTaken = takenMedications.contains(medicationKey);

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

    // Update taken medications set
    ref.read(takenMedicationsProvider.notifier).update((state) =>
        value ? {...state, medicationKey} : state.difference({medicationKey}));

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
