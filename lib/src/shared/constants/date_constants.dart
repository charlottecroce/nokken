//
//  date_constants.dart
//  Constants for dates and timing
//
class DateConstants {
  /// Map of day abbreviations to full day names
  static const Map<String, String> dayNames = {
    'Su': 'Sunday',
    'M': 'Monday',
    'T': 'Tuesday',
    'W': 'Wednesday',
    'Th': 'Thursday',
    'F': 'Friday',
    'Sa': 'Saturday'
  };

  /// Day abbreviations in order (Sunday first)
  static const List<String> orderedDays = [
    'Su',
    'M',
    'T',
    'W',
    'Th',
    'F',
    'Sa'
  ];

  /// Map from DateTime weekday integers to day abbreviations
  /// Note: Flutter uses 1-7 (Monday-Sunday) for weekdays
  static const Map<int, String> dayMap = {
    DateTime.monday: 'M',
    DateTime.tuesday: 'T',
    DateTime.wednesday: 'W',
    DateTime.thursday: 'Th',
    DateTime.friday: 'F',
    DateTime.saturday: 'Sa',
    DateTime.sunday: 'Su',
  };

  /// List of month abbreviations
  static const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  /// Converts day abbreviation to weekday number (0-6)
  /// Used for calendar calculations
  static int dayAbbreviationToWeekday(String dayAbbr) {
    const Map<String, int> dayMap = {
      'Su': 0, // Sunday (Flutter uses 7 for Sunday, but we'll normalize to 0)
      'M': 1, // Monday
      'T': 2, // Tuesday
      'W': 3, // Wednesday
      'Th': 4, // Thursday
      'F': 5, // Friday
      'Sa': 6, // Saturday
    };

    return dayMap[dayAbbr] ?? 0; // Default to Sunday if not found
  }
}
