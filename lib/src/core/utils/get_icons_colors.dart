import 'package:flutter/material.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/app_icons.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';

class GetIconsColors {
  ///-------------------------------
  /// MEDICATION TYPES
  ///-------------------------------

  /// Get appropriate icon based on medication type
  static IconData getMedicationIcon(MedicationType medicationType) {
    switch (medicationType) {
      case MedicationType.oral:
        return AppIcons.getOutlined('medication');
      case MedicationType.injection:
        return AppIcons.getOutlined('vaccine');
      case MedicationType.topical:
        return AppIcons.getOutlined('topical');
      case MedicationType.patch:
        return AppIcons.getOutlined('patch');
    }
  }

  /// Get appropriate color based on medication type
  static Color getMedicationColor(MedicationType medicationType) {
    switch (medicationType) {
      case MedicationType.oral:
        return AppColors.oralMedication;
      case MedicationType.injection:
        return AppColors.injection;
      case MedicationType.topical:
        return AppColors.topical;
      case MedicationType.patch:
        return AppColors.patch;
    }
  }

  /// Get appropriate Icon and color based on medication type
  static Icon getMedicationIconWithColor(MedicationType medicationType) {
    return Icon(getMedicationIcon(medicationType),
        color: getMedicationColor(medicationType));
  }

  static CircleAvatar getMedicationIconCirlce(MedicationType medicationType) {
    return CircleAvatar(
      backgroundColor: getMedicationColor(medicationType).withAlpha(40),
      child: getMedicationIconWithColor(medicationType),
    );
  }

  ///-------------------------------
  /// APPOINTMENT TYPES
  ///-------------------------------
  /// Get an icon for an appointment type
  static IconData getAppointmentIcon(AppointmentType appointmentType) {
    switch (appointmentType) {
      case AppointmentType.bloodwork:
        return AppIcons.getOutlined('bloodwork');
      case AppointmentType.appointment:
        return AppIcons.getOutlined('medical_services');
      case AppointmentType.surgery:
        return AppIcons.getOutlined('medical_info');
    }
  }

  static Color getAppointmentColor(AppointmentType appointmentType) {
    switch (appointmentType) {
      case AppointmentType.bloodwork:
        return AppColors.bloodwork;
      case AppointmentType.appointment:
        return AppColors.doctorAppointment;
      case AppointmentType.surgery:
        return AppColors.surgery;
    }
  }

  /// Get appropriate Icon and color based on appointment type
  static Icon getAppointmentIconWithColor(AppointmentType appointmentType) {
    return Icon(getAppointmentIcon(appointmentType),
        color: getAppointmentColor(appointmentType));
  }

  static CircleAvatar getAppointmentIconCirlce(
      AppointmentType appointmentType) {
    return CircleAvatar(
      backgroundColor: getAppointmentColor(appointmentType).withAlpha(40),
      child: getAppointmentIconWithColor(appointmentType),
    );
  }
}
