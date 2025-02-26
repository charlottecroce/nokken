import 'package:flutter/material.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;

  const BasicInfoSection({
    super.key,
    required this.nameController,
    required this.dosageController,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Basic Information',
      children: [
        TextFormField(
          controller: nameController,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Medication Name',
          ),
          validator: (value) => value?.trim().isEmpty == true
              ? 'Please enter a medication name'
              : null,
        ),
        SharedWidgets.verticalSpace(),
        TextFormField(
          controller: dosageController,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Dosage',
            hintText: 'e.g., 50mg',
          ),
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Please enter the dosage' : null,
        ),
      ],
    );
  }
}
