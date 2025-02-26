//flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//constants
import 'package:nokken/src/shared/constants/date_constants.dart';
//widgets
import 'package:nokken/src/shared/theme/shared_widgets.dart';
//ui
import 'package:nokken/src/shared/theme/app_theme.dart';

class TimingSection extends StatelessWidget {
  final int frequency;
  final List<TimeOfDay> times;
  final Set<String> selectedDays;
  final ValueChanged<int> onFrequencyChanged;
  final Function(int, TimeOfDay) onTimeChanged;
  final ValueChanged<Set<String>> onDaysChanged;
  final DateTime selectedStartDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final bool isEveryTwoWeeks;

  const TimingSection({
    super.key,
    required this.frequency,
    required this.times,
    required this.selectedDays,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onDaysChanged,
    required this.selectedStartDate,
    required this.onStartDateChanged,
    this.isEveryTwoWeeks = false,
  });

  Widget _buildFrequencySelector() {
    return Row(
      children: [
        const Text('Times per day: '),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed:
              frequency > 1 ? () => onFrequencyChanged(frequency - 1) : null,
        ),
        Text('$frequency'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed:
              frequency < 10 ? () => onFrequencyChanged(frequency + 1) : null,
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacing,
      children: [
        Text('Days: ', style: AppTextStyles.titleMedium),
        ...DateConstants.orderedDays.map((day) {
          final bool isSelected = selectedDays.contains(day);
          final bool canToggle =
              !isEveryTwoWeeks || selectedDays.length > 1 || !isSelected;

          return TextButton(
            onPressed: canToggle
                ? () {
                    final newDays = Set<String>.from(selectedDays);
                    if (isSelected) {
                      newDays.remove(day);
                    } else {
                      newDays.add(day);
                    }
                    onDaysChanged(newDays);
                  }
                : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              side: BorderSide(
                color: AppColors.outline,
              ),
              backgroundColor: isSelected ? AppColors.secondary : null,
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: AppTheme.bodyMedium.fontSize,
                color: isSelected ? AppColors.onPrimary : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2034),
    );
    if (picked != null && picked != selectedStartDate) {
      onStartDateChanged(picked);
    }
  }

  Widget _buildStartDateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ListTile(
          title: Text(
            'Start Date: ${_formatDate(selectedStartDate)}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectStartDate(context),
        ),
      ],
    );
  }

  Widget _buildTimeInput(BuildContext context, int index) {
    final time = times[index];
    final isPM = time.hour >= 12;
    final hour12 =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Time ${index + 1}:',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          // Hour input
          SizedBox(
            width: 45,
            child: TextFormField(
              initialValue: hour12.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: AppTheme.defaultTextFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final newHour = int.parse(value);
                  if (newHour >= 1 && newHour <= 12) {
                    final hour24 = isPM
                        ? (newHour == 12 ? 12 : newHour + 12)
                        : (newHour == 12 ? 0 : newHour);
                    onTimeChanged(
                      index,
                      TimeOfDay(hour: hour24, minute: time.minute),
                    );
                  }
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(':', style: TextStyle(fontSize: 20)),
          ),
          // Minute input
          SizedBox(
            width: 45,
            child: TextFormField(
              initialValue: time.minute.toString().padLeft(2, '0'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: AppTheme.defaultTextFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final newMinute = int.parse(value);
                  if (newMinute >= 0 && newMinute < 60) {
                    onTimeChanged(
                      index,
                      TimeOfDay(hour: time.hour, minute: newMinute),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // AM/PM toggle
          TextButton(
            onPressed: () {
              final currentHour = time.hour;
              final hour12 = currentHour > 12
                  ? currentHour - 12
                  : (currentHour == 0 ? 12 : currentHour);

              final newIsPM = !isPM;
              final newHour = newIsPM
                  ? (hour12 == 12 ? 12 : hour12 + 12)
                  : (hour12 == 12 ? 0 : hour12);

              onTimeChanged(
                index,
                TimeOfDay(hour: newHour, minute: time.minute),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: AppColors.outline),
            ),
            child: Text(
              isPM ? 'PM' : 'AM',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Timing',
      children: [
        _buildStartDateSelector(context),
        if (!isEveryTwoWeeks) _buildFrequencySelector(),
        SharedWidgets.verticalSpace(16),
        _buildDaySelector(context),
        SharedWidgets.verticalSpace(16),
        ...List.generate(
          frequency,
          (index) => _buildTimeInput(context, index),
        ),
      ],
    );
  }
}
