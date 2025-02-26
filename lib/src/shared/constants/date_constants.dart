//
//  date_constants.dart
//  constants and functions to format dates and timing
//
class DateConstants {
  static const Map<String, String> dayNames = {
    'Su': 'Sunday',
    'M': 'Monday',
    'T': 'Tuesday',
    'W': 'Wednesday',
    'Th': 'Thursday',
    'F': 'Friday',
    'Sa': 'Saturday'
  };

  static const List<String> orderedDays = [
    'Su',
    'M',
    'T',
    'W',
    'Th',
    'F',
    'Sa'
  ];

  static const Map<int, String> dayMap = {
    DateTime.monday: 'M',
    DateTime.tuesday: 'T',
    DateTime.wednesday: 'W',
    DateTime.thursday: 'Th',
    DateTime.friday: 'F',
    DateTime.saturday: 'Sa',
    DateTime.sunday: 'Su',
  };

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

// converts day abbreviation to weekday number
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

  static String formatDate(DateTime date) {
    final now = DateTime.now();

    String formatDateString() {
      return '${DateConstants.months[date.month - 1]} ${date.day}, ${date.year}';
    }

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today - ${formatDateString()}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow - ${formatDateString()}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday - ${formatDateString()}';
    }

    return formatDateString();
  }
}
