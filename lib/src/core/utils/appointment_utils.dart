//
//  appointment_utils.dart
//  Utilities for appointment-related functionality
//
import 'package:flutter/material.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/app_icons.dart';

/// Utility functions for appointment-related operations
class AppointmentUtils {
  /// Get color for a specific appointment type
  static Color getAppointmentTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.bloodwork:
        return AppColors.bloodwork;
      case AppointmentType.appointment:
        return AppColors.doctorAppointment;
      case AppointmentType.surgery:
        return AppColors.surgery;
    }
  }

  /// Get a text description for an appointment type
  static String getAppointmentTypeText(AppointmentType type) {
    switch (type) {
      case AppointmentType.bloodwork:
        return 'Bloodwork';
      case AppointmentType.appointment:
        return 'Doctor Visit';
      case AppointmentType.surgery:
        return 'Surgery';
    }
  }

  /// Get an icon for an appointment type
  static IconData getAppointmentTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.bloodwork:
        return AppIcons.getOutlined('bloodwork');
      case AppointmentType.appointment:
        return AppIcons.getOutlined('medical_services');
      case AppointmentType.surgery:
        return AppIcons.getOutlined('medical_info');
    }
  }
}
