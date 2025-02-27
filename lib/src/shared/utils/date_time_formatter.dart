//
//  date_time_formatter.dart
//  A utility class for formatting dates, times, and related display elements
//

import 'package:flutter/material.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';

class DateTimeFormatter {
  //----------------------------------------------------------------------------
  // DATE FORMATTING FUNCTIONS
  //----------------------------------------------------------------------------

  /// Formats a date as "Month Day, Year" with special handling for today,
  /// tomorrow and yesterday.
  ///
  /// Examples:
  /// - Today - Jan 1, 2025
  /// - Tomorrow - Jan 2, 2025
  /// - Jan 15, 2025
  static String formatDateMMMDDYYYY(DateTime date) {
    final now = DateTime.now();

    /// Helper function to create the base date string
    String formatDateStringMMMDDYYYY() {
      return '${DateConstants.months[date.month - 1]} ${date.day}, ${date.year}';
    }

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today - ${formatDateStringMMMDDYYYY()}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow - ${formatDateStringMMMDDYYYY()}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday - ${formatDateStringMMMDDYYYY()}';
    }

    return formatDateStringMMMDDYYYY();
  }

  /// Formats a date in MM/DD/YYYY format
  ///
  /// Example: 2/26/2025
  static String formatDateDDMMYY(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Formats a set of days of the week into a human-readable string
  ///
  /// If all 7 days are included, returns "Everyday"
  /// Otherwise, returns a comma-separated list of day names
  static String formatDaysOfWeek(Set<String> days) {
    if (days.length == 7 && DateConstants.orderedDays.every(days.contains)) {
      return 'Everyday';
    }

    final sortedDays = days.toList()
      ..sort((a, b) => DateConstants.orderedDays
          .indexOf(a)
          .compareTo(DateConstants.orderedDays.indexOf(b)));

    return sortedDays.map((day) => DateConstants.dayNames[day]).join(', ');
  }

  //----------------------------------------------------------------------------
  // MEDICATION-SPECIFIC FORMATTING
  //----------------------------------------------------------------------------

  /// Returns a string describing the frequency of a medication
  static String formatMedicationFrequency(Medication medication) {
    if (medication.medicationType == MedicationType.injection) {
      return 'every week';
    }
    if (medication.injectionDetails?.frequency == InjectionFrequency.biweekly) {
      return 'every 2 weeks';
    }
    String frequencyText = medication.frequency == 1
        ? 'once'
        : medication.frequency == 2
            ? 'twice'
            : '${medication.frequency} times';

    return '$frequencyText a day';
  }

  /// Creates a comprehensive description of medication dosage and schedule
  ///
  /// Accounts for medication type (oral vs. injection) and frequency
  ///
  /// Examples:
  /// - "Take 10mg once daily, everyday"
  /// - "Take 5mg twice daily, on Mon, Wed, Fri"
  /// - "Inject 15ml on Tue, Thu"
  static String formatMedicationFrequencyDosage(Medication medication) {
    // Format frequency text (once/twice/three times)
    String frequencyText = medication.frequency == 1
        ? 'once'
        : medication.frequency == 2
            ? 'twice'
            : '${medication.frequency} times';

    if (medication.medicationType == MedicationType.oral) {
      if (medication.daysOfWeek.isEmpty || medication.daysOfWeek.length == 7) {
        return 'Take ${medication.dosage} $frequencyText daily, everyday';
      } else {
        return 'Take ${medication.dosage} $frequencyText daily, on ${medication.daysOfWeek.join(', ')}';
      }
    } else {
      return 'Inject ${medication.dosage} on ${medication.daysOfWeek.join(', ')}';
    }
  }

  //----------------------------------------------------------------------------
  // TIME PARSING AND FORMATTING
  //----------------------------------------------------------------------------

  /// Parses a time string in various formats (like "8:30 AM") to a TimeOfDay object
  ///
  /// Handles both 12-hour and 24-hour formats
  ///
  /// @param timeStr The time string to parse
  /// @return A TimeOfDay representation of the input string
  static TimeOfDay parseTimeString(String timeStr) {
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

  /// Formats a TimeOfDay object to a 12-hour AM/PM time string
  ///
  /// @param time The TimeOfDay object to format
  /// @return A formatted string like "8:30 AM"
  static String formatTimeToAMPM(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Compares two time strings for sorting
  ///
  /// @param a First time string (e.g., "8:30 AM")
  /// @param b Second time string (e.g., "2:45 PM")
  /// @return A negative value if a is earlier than b,
  ///         positive if a is later than b,
  ///         zero if they are the same time
  static int compareTimeSlots(String a, String b) {
    final timeA = parseTimeString(a);
    final timeB = parseTimeString(b);
    return timeA.hour * 60 + timeA.minute - (timeB.hour * 60 + timeB.minute);
  }

  //----------------------------------------------------------------------------
  // TIME ICON SELECTION
  //----------------------------------------------------------------------------

  /// Returns an appropriate icon based on the time of day
  ///
  /// Time ranges:
  /// - 5:00-8:59 AM: twilight icon (dawn)
  /// - 9:00 AM-4:59 PM: sun icon (daytime)
  /// - 5:00-8:59 PM: twilight icon (dusk)
  /// - 9:00 PM-4:59 AM: moon icon (noon)
  ///
  /// @param timeOfDay A TimeOfDay object
  /// @return An IconData object for the corresponding time period
  static IconData getTimeIconFromTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour;

    if (hour >= 5 && hour < 9) {
      return AppIcons.getFilled('twilight');
    } else if (hour >= 9 && hour < 17) {
      return AppIcons.getFilled('sun');
    } else if (hour >= 17 && hour < 21) {
      return AppIcons.getFilled('twilight');
    } else {
      return AppIcons.getFilled('night');
    }
  }

  /// Gets an icon appropriate for the given time string
  ///
  /// @param timeSlot A string representation of time (e.g., "8:30 AM")
  /// @return An IconData object for the corresponding time period
  static IconData getTimeIcon(String timeSlot) {
    final timeOfDay = parseTimeString(timeSlot);
    return getTimeIconFromTimeOfDay(timeOfDay);
  }
}
