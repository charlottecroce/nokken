//
//  calendar.dart
//
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class MedicationCalendar extends StatefulWidget {
  final List<Medication> medications;
  final Function(DateTime) onDaySelected;

  const MedicationCalendar({
    Key? key,
    required this.medications,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
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

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: const TextStyle(
          color: AppTheme.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.black),
        rightChevronIcon:
            const Icon(Icons.chevron_right, color: AppTheme.black),
        headerPadding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.lightgreyDark.withAlpha(40),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle:
            const TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(
            color: AppTheme.black.withAlpha(80), fontWeight: FontWeight.bold),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: AppTheme.black),
        weekendTextStyle: TextStyle(color: AppTheme.black.withAlpha(80)),
        outsideTextStyle: const TextStyle(color: AppTheme.lightgreyDark),

        // Today styling
        todayDecoration: BoxDecoration(
          color: AppTheme.blueDark.withAlpha(40),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.blueDark, width: 1.5),
        ),
        todayTextStyle: const TextStyle(
            color: AppTheme.blueDark, fontWeight: FontWeight.bold),

        // Selected day styling
        selectedDecoration: const BoxDecoration(
          color: AppTheme.blueDark,
          shape: BoxShape.circle,
        ),
        selectedTextStyle:
            const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),

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
              color: AppColors.primary,
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
