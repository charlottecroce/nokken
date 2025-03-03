import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';

class GetLabels {
  ///-------------------------------
  /// MEDICATION TYPES
  ///-------------------------------

  /// Get a text description of the medication type and subtype
  static String getMedicationTypeText(Medication medication) {
    switch (medication.medicationType) {
      case MedicationType.oral:
        String subtypeText;
        switch (medication.oralSubtype) {
          case OralSubtype.tablets:
            subtypeText = 'Tablets';
            break;
          case OralSubtype.capsules:
            subtypeText = 'Capsules';
            break;
          case OralSubtype.drops:
            subtypeText = 'Drops';
            break;
          case null:
            subtypeText = 'Oral';
            break;
        }
        return 'Oral${subtypeText.isNotEmpty ? ' - $subtypeText' : ''}';

      case MedicationType.injection:
        return 'Injection';

      case MedicationType.topical:
        String subtypeText;
        switch (medication.topicalSubtype) {
          case TopicalSubtype.gel:
            subtypeText = 'Gel';
            break;
          case TopicalSubtype.cream:
            subtypeText = 'Cream';
            break;
          case TopicalSubtype.spray:
            subtypeText = 'Spray';
            break;
          case null:
            subtypeText = 'Topical';
            break;
        }
        return 'Topical${subtypeText.isNotEmpty ? ' - $subtypeText' : ''}';

      case MedicationType.patch:
        return 'Patch';
    }
  }

  /// Get a text description of the injection subtype
  static String getInjectionSubtypeText(InjectionSubtype injectionSubtype) {
    switch (injectionSubtype) {
      case InjectionSubtype.intravenous:
        return 'Intravenous (IV)';
      case InjectionSubtype.intramuscular:
        return 'Intramuscular (IM)';
      case InjectionSubtype.subcutaneous:
        return 'Subcutaneous (SC)';
    }
  }

  ///-------------------------------
  /// APPOINTMENT TYPES
  ///-------------------------------
  ///

  /// Get a text description for an appointment type
  static String getAppointmentTypeText(AppointmentType appointmentType) {
    switch (appointmentType) {
      case AppointmentType.bloodwork:
        return 'Bloodwork';
      case AppointmentType.appointment:
        return 'Doctor Visit';
      case AppointmentType.surgery:
        return 'Surgery';
    }
  }
}
