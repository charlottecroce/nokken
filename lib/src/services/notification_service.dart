import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'dart:io' show Platform;

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);

  @override
  String toString() => 'NotificationException: $message';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (_isInitialized || !_isMobilePlatform) return;

    try {
      tz.initializeTimeZones();

      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(initializationSettings);
      _isInitialized = true;
    } catch (e) {
      if (_isMobilePlatform) {
        throw NotificationException('Failed to initialize notifications: $e');
      }
    }
  }

  Future<void> scheduleMedicationReminders(Medication medication) async {
    if (!_isMobilePlatform) {
      // Silently fail on non-mobile platforms
      //print('Skipping notification scheduling on non-mobile platform');
      return;
    }

    try {
      await initialize();

      // Cancel existing notifications for this medication
      await cancelMedicationReminders(medication.id);

      // Schedule new notifications for each time
      for (final time in medication.timeOfDay) {
        final now = DateTime.now();
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

        await _notifications.zonedSchedule(
          medication.id.hashCode + time.hashCode,
          'Medication Reminder',
          'Time to take ${medication.name} - ${medication.dosage}',
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_reminders',
              'Medication Reminders',
              channelDescription: 'Reminders to take medications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: medication.id,
        );
      }

      // Schedule refill reminder if needed
      if (medication.needsRefill()) {
        await _notifications.zonedSchedule(
          medication.id.hashCode,
          'Refill Reminder',
          'Time to refill ${medication.name}',
          tz.TZDateTime.now(tz.local).add(const Duration(days: 1)),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'refill_reminders',
              'Refill Reminders',
              channelDescription: 'Reminders to refill medications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'refill_${medication.id}',
        );
      }
    } catch (e) {
      if (_isMobilePlatform) {
        throw NotificationException('Failed to schedule reminders: $e');
      }
      //print('Error scheduling notifications on non-mobile platform: $e');
    }
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    if (!_isMobilePlatform) {
      //print('Skipping notification cancellation on non-mobile platform');
      return;
    }

    try {
      await _notifications.cancel(medicationId.hashCode);
      for (var i = 0; i < 10; i++) {
        await _notifications
            .cancel(medicationId.hashCode + DateTime.now().hour.hashCode + i);
      }
    } catch (e) {
      if (_isMobilePlatform) {
        throw NotificationException('Failed to cancel reminders: $e');
      }
      //print('Error cancelling notifications on non-mobile platform: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!_isMobilePlatform) {
      //print('Skipping permission request on non-mobile platform');
      return;
    }

    try {
      await initialize();

      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      if (_isMobilePlatform) {
        throw NotificationException('Failed to request permissions: $e');
      }
      //print('Error requesting permissions on non-mobile platform: $e');
    }
  }
}
