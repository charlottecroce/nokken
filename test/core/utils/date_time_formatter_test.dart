// test/core/utils/date_time_formatter_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nokken/src/core/utils/date_time_formatter.dart';

void main() {
  group('DateTimeFormatter', () {
    group('formatTimeToAMPM', () {
      test('should format morning time correctly', () {
        // Morning time (9:30 AM)
        final time = const TimeOfDay(hour: 9, minute: 30);

        // Format and check
        final result = DateTimeFormatter.formatTimeToAMPM(time);
        expect(result, '9:30 AM');
      });

      test('should format afternoon time correctly', () {
        // Afternoon time (2:45 PM)
        final time = const TimeOfDay(hour: 14, minute: 45);

        // Format and check
        final result = DateTimeFormatter.formatTimeToAMPM(time);
        expect(result, '2:45 PM');
      });

      test('should handle midnight correctly', () {
        // Midnight (12:00 AM)
        final time = const TimeOfDay(hour: 0, minute: 0);

        // Format and check
        final result = DateTimeFormatter.formatTimeToAMPM(time);
        expect(result, '12:00 AM');
      });

      test('should handle noon correctly', () {
        // Noon (12:00 PM)
        final time = const TimeOfDay(hour: 12, minute: 0);

        // Format and check
        final result = DateTimeFormatter.formatTimeToAMPM(time);
        expect(result, '12:00 PM');
      });

      test('should pad minutes with leading zero', () {
        // 9:05 AM (single-digit minute)
        final time = const TimeOfDay(hour: 9, minute: 5);

        // Format and check
        final result = DateTimeFormatter.formatTimeToAMPM(time);
        expect(result, '9:05 AM');
      });
    });

    group('parseTimeString', () {
      test('should parse time in AM/PM format', () {
        // Parse time string
        final result = DateTimeFormatter.parseTimeString('3:45 PM');

        // Verify hour and minute
        expect(result.hour, 15);
        expect(result.minute, 45);
      });

      test('should handle 12 PM correctly', () {
        // Parse noon
        final result = DateTimeFormatter.parseTimeString('12:00 PM');

        // Verify hour and minute
        expect(result.hour, 12);
        expect(result.minute, 0);
      });

      test('should handle 12 AM correctly', () {
        // Parse midnight
        final result = DateTimeFormatter.parseTimeString('12:00 AM');

        // Verify hour and minute
        expect(result.hour, 0);
        expect(result.minute, 0);
      });
    });

    group('compareTimeSlots', () {
      test('earlier time should be less than later time', () {
        // Compare 9:00 AM to 2:00 PM
        final result = DateTimeFormatter.compareTimeSlots('9:00 AM', '2:00 PM');

        // Result should be negative (first time is earlier)
        expect(result < 0, isTrue);
      });

      test('equal times should return zero', () {
        // Compare 9:00 AM to 9:00 AM
        final result = DateTimeFormatter.compareTimeSlots('9:00 AM', '9:00 AM');

        // Result should be zero (times are equal)
        expect(result, equals(0));
      });

      test('PM times should be later than AM times', () {
        // Compare 9:00 PM to 9:00 AM
        final result = DateTimeFormatter.compareTimeSlots('9:00 PM', '9:00 AM');

        // Result should be positive (first time is later)
        expect(result > 0, isTrue);
      });
    });
  });
}
