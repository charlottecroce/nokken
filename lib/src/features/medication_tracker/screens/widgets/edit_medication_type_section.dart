// medication_type_section.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/shared_widgets.dart';
import '../../models/medication.dart';

class MedicationTypeSection extends StatelessWidget {
  final MedicationType medicationType;
  final ValueChanged<MedicationType> onTypeChanged; // Non-nullable type

  const MedicationTypeSection({
    super.key,
    required this.medicationType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Medication Type',
      children: [
        RadioListTile<MedicationType>(
          title: const Text('Oral'),
          value: MedicationType.oral,
          groupValue: medicationType,
          onChanged: (value) {
            if (value != null) {
              onTypeChanged(value);
            }
          },
        ),
        RadioListTile<MedicationType>(
          title: const Text('Injection'),
          value: MedicationType.injection,
          groupValue: medicationType,
          onChanged: (value) {
            if (value != null) {
              onTypeChanged(value);
            }
          },
        ),
      ],
    );
  }
}
