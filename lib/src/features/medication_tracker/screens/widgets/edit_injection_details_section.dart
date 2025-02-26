import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class InjectionDetailsSection extends StatelessWidget {
  final InjectionDetails injectionDetails;
  final Function({
    String? drawingNeedleType,
    int? drawingNeedleCount,
    int? drawingNeedleRefills,
    String? injectingNeedleType,
    int? injectingNeedleCount,
    int? injectingNeedleRefills,
    String? injectionSiteNotes,
    InjectionFrequency? frequency,
  }) onDetailsChanged;

  const InjectionDetailsSection({
    super.key,
    required this.injectionDetails,
    required this.onDetailsChanged,
  });

  Widget _buildNeedleSection({
    required BuildContext context,
    required String title,
    required String type,
    required int count,
    required int refills,
    required Function(String) onTypeChanged,
    required Function(int) onCountChanged,
    required Function(int) onRefillsChanged,
    String typeHint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SharedWidgets.verticalSpace(),
        TextFormField(
          initialValue: type,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Needle Type',
            hintText: typeHint,
          ),
          onChanged: onTypeChanged,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter needle type' : null,
        ),
        SharedWidgets.verticalSpace(),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: count.toString(),
                decoration: AppTheme.defaultTextFieldDecoration.copyWith(
                  labelText: 'Count',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onCountChanged(int.tryParse(value) ?? 0),
                validator: (value) => int.tryParse(value ?? '') == null
                    ? 'Enter valid number'
                    : null,
              ),
            ),
            SharedWidgets.verticalSpace(),
            Expanded(
              child: TextFormField(
                initialValue: refills.toString(),
                decoration: AppTheme.defaultTextFieldDecoration.copyWith(
                  labelText: 'Refills',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) =>
                    onRefillsChanged(int.tryParse(value) ?? 0),
                validator: (value) => int.tryParse(value ?? '') == null
                    ? 'Enter valid number'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Injection Details',
      children: [
        // Frequency Dropdown
        DropdownButtonFormField<InjectionFrequency>(
          value: injectionDetails.frequency,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Frequency',
          ),
          items: InjectionFrequency.values.map((freq) {
            return DropdownMenuItem(
              value: freq,
              child: Text(
                freq == InjectionFrequency.weekly ? 'Weekly' : 'Every 2 Weeks',
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onDetailsChanged(frequency: value);
            }
          },
        ),
        SharedWidgets.verticalSpace(24),

        // Drawing Needles Section
        _buildNeedleSection(
          context: context,
          title: 'Drawing Needles',
          type: injectionDetails.drawingNeedleType,
          count: injectionDetails.drawingNeedleCount,
          refills: injectionDetails.drawingNeedleRefills,
          typeHint: 'e.g., 18G 1.5"',
          onTypeChanged: (value) => onDetailsChanged(drawingNeedleType: value),
          onCountChanged: (value) =>
              onDetailsChanged(drawingNeedleCount: value),
          onRefillsChanged: (value) =>
              onDetailsChanged(drawingNeedleRefills: value),
        ),
        SharedWidgets.verticalSpace(24),

        // Injecting Needles Section
        _buildNeedleSection(
          context: context,
          title: 'Injecting Needles',
          type: injectionDetails.injectingNeedleType,
          count: injectionDetails.injectingNeedleCount,
          refills: injectionDetails.injectingNeedleRefills,
          typeHint: 'e.g., 25G 1"',
          onTypeChanged: (value) =>
              onDetailsChanged(injectingNeedleType: value),
          onCountChanged: (value) =>
              onDetailsChanged(injectingNeedleCount: value),
          onRefillsChanged: (value) =>
              onDetailsChanged(injectingNeedleRefills: value),
        ),
        SharedWidgets.verticalSpace(24),

        // Injection Site Notes
        Text(
          'Injection Site Notes',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SharedWidgets.verticalSpace(),
        TextFormField(
          initialValue: injectionDetails.injectionSiteNotes,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            hintText: 'Enter notes about injection sites, rotation, etc.',
          ),
          maxLines: 3,
          onChanged: (value) => onDetailsChanged(injectionSiteNotes: value),
        ),
      ],
    );
  }
}
