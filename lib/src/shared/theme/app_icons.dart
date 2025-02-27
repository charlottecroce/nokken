//
//  app_icons.dart
//  Centralized icon management
//
import 'package:flutter/material.dart';

/// Provides outlined and filled versions of each icon
class AppIcons {
  // Map of icon pairs where key is a string identifier and value is a pair of outlined/filled icons
  static final Map<String, ({IconData outlined, IconData filled})> iconMap = {
    // Navigation
    'home': (outlined: Icons.home_outlined, filled: Icons.home),
    'settings': (outlined: Icons.settings_outlined, filled: Icons.settings),
    'profile': (outlined: Icons.person_outline, filled: Icons.person),
    'menu': (outlined: Icons.menu_outlined, filled: Icons.menu),

    // Time of day
    'sun': (outlined: Icons.wb_sunny_outlined, filled: Icons.wb_sunny),
    'twilight': (
      outlined: Icons.wb_twilight_outlined,
      filled: Icons.wb_twilight
    ),
    'night': (outlined: Icons.bedtime_outlined, filled: Icons.bedtime),

    // Actions
    'add': (outlined: Icons.add, filled: Icons.add),
    'edit': (outlined: Icons.edit_outlined, filled: Icons.edit),
    'delete': (outlined: Icons.delete_outline, filled: Icons.delete),
    'save': (outlined: Icons.save_outlined, filled: Icons.save),
    'refresh': (outlined: Icons.refresh_outlined, filled: Icons.refresh),
    'redo': (outlined: Icons.redo_outlined, filled: Icons.redo),
    'undo': (outlined: Icons.undo_outlined, filled: Icons.undo),

    // Arrows
    'arrow_back': (
      outlined: Icons.arrow_back_outlined,
      filled: Icons.arrow_back
    ),
    'arrow_forward': (
      outlined: Icons.arrow_forward_outlined,
      filled: Icons.arrow_forward
    ),
    'arrow_up': (
      outlined: Icons.arrow_upward_outlined,
      filled: Icons.arrow_upward
    ),
    'arrow_down': (
      outlined: Icons.arrow_downward_outlined,
      filled: Icons.arrow_downward
    ),
    'arrow_left': (
      outlined: Icons.arrow_left_outlined,
      filled: Icons.arrow_left
    ),
    'arrow_right': (
      outlined: Icons.arrow_right_outlined,
      filled: Icons.arrow_right
    ),
    'arrow_circle_left': (
      outlined: Icons.arrow_circle_left_outlined,
      filled: Icons.arrow_circle_left
    ),
    'arrow_circle_right': (
      outlined: Icons.arrow_circle_right_outlined,
      filled: Icons.arrow_circle_right
    ),
    'arrow_circle_up': (
      outlined: Icons.arrow_circle_up_outlined,
      filled: Icons.arrow_circle_up
    ),
    'arrow_circle_down': (
      outlined: Icons.arrow_circle_down_outlined,
      filled: Icons.arrow_circle_down
    ),
    'arrow_back_ios': (
      outlined: Icons.arrow_back_ios_outlined,
      filled: Icons.arrow_back_ios
    ),
    'arrow_forward_ios': (
      outlined: Icons.arrow_forward_ios_outlined,
      filled: Icons.arrow_forward_ios
    ),
    'chevron_left': (
      outlined: Icons.chevron_left_outlined,
      filled: Icons.chevron_left
    ),
    'chevron_right': (
      outlined: Icons.chevron_right_outlined,
      filled: Icons.chevron_right
    ),

    // Communication
    'message': (outlined: Icons.message_outlined, filled: Icons.message),
    'notification': (
      outlined: Icons.notifications_outlined,
      filled: Icons.notifications
    ),
    'email': (outlined: Icons.email_outlined, filled: Icons.email),
    'phone': (outlined: Icons.phone_outlined, filled: Icons.phone),

    // Medical
    'medication': (
      outlined: Icons.medication_outlined,
      filled: Icons.medication
    ),
    'pharmacy': (
      outlined: Icons.local_pharmacy_outlined,
      filled: Icons.local_pharmacy
    ),
    'medical_services': (
      outlined: Icons.medical_services_outlined,
      filled: Icons.medical_services
    ),
    'vaccine': (outlined: Icons.vaccines_outlined, filled: Icons.vaccines),

    // Status
    'success': (
      outlined: Icons.check_circle_outline,
      filled: Icons.check_circle
    ),
    'warning': (outlined: Icons.warning_outlined, filled: Icons.warning),
    'error': (outlined: Icons.error_outline, filled: Icons.error),
    'info': (outlined: Icons.info_outline, filled: Icons.info),

    // Time related
    'calendar': (
      outlined: Icons.calendar_today_outlined,
      filled: Icons.calendar_today
    ),
    'clock': (outlined: Icons.access_time_outlined, filled: Icons.access_time),
    'alarm': (outlined: Icons.alarm_outlined, filled: Icons.alarm),
    'schedule': (outlined: Icons.schedule_outlined, filled: Icons.schedule),
  };

  /// Get the outlined version of an icon
  static IconData getOutlined(String name) {
    return iconMap[name]?.outlined ?? Icons.error_outline;
  }

  /// Get the filled version of an icon
  static IconData getFilled(String name) {
    return iconMap[name]?.filled ?? Icons.error;
  }

  /// Get icon based on selected state (filled when selected, outlined when not)
  static IconData getIcon(String name, {bool selected = false}) {
    return selected ? getFilled(name) : getOutlined(name);
  }
}
