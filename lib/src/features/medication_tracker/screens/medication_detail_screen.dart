//
//  medication_detail_screen.dart
//  Screen that displays more detailed information about a medication
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/core/theme/app_icons.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/core/services/navigation/navigation_service.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/theme/shared_widgets.dart';
//import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/core/utils/date_time_formatter.dart';

class MedicationDetailScreen extends ConsumerWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(AppIcons.getIcon('arrow_back')),
              onPressed: () => NavigationService.goHome(context),
            ),
          ],
        ),
        actions: [
          // Edit button
          IconButton(
            icon: Icon(AppIcons.getIcon('edit')),
            onPressed: () => NavigationService.goToMedicationAddEdit(context,
                medication: medication),
          ),
          // Delete button
          IconButton(
            icon: Icon(AppIcons.getIcon('delete')),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: AppTheme.standardCardPadding,
        children: [
          // Refill alert banner
          if (medication.needsRefill())
            Card(
              color: AppColors.errorContainer,
              child: Padding(
                padding: AppTheme.standardCardPadding,
                child: Row(
                  children: [
                    Icon(
                      AppIcons.getIcon('warning'),
                      color: AppColors.error,
                    ),
                    SharedWidgets.verticalSpace(),
                    Text(
                      'Refill needed',
                      style: AppTextStyles.error,
                    ),
                  ],
                ),
              ),
            ),

          // Basic medication information card
          Card(
            child: Padding(
              padding: AppTheme.standardCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMedicationTypeIcon(),
                      SharedWidgets.verticalSpace(),
                      Expanded(
                        child: Text(
                          medication.name,
                          style: AppTextStyles.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SharedWidgets.verticalSpace(AppTheme.cardPadding),
                  _buildInfoRow('Dosage', medication.dosage),
                  SharedWidgets.verticalSpace(),
                  _buildInfoRow('Type', _getMedicationTypeText()),
                  SharedWidgets.verticalSpace(),
                  _buildInfoRow('Frequency',
                      DateTimeFormatter.formatMedicationFrequency(medication)),
                  SharedWidgets.verticalSpace(),
                  if (medication.currentQuantity > 0 &&
                      medication.refillThreshold > 0)
                    _buildInfoRow('Remaining / Refill',
                        '${medication.currentQuantity} / ${medication.refillThreshold}'),
                ],
              ),
            ),
          ),
          SharedWidgets.verticalSpace(AppTheme.cardSpacing),

          // Healthcare Providers card (if either doctor or pharmacy is provided)
          if (medication.doctor != null || medication.pharmacy != null) ...[
            SharedWidgets.basicCard(
              context: context,
              title: 'Healthcare Providers',
              children: [
                if (medication.doctor != null)
                  _buildInfoRow('Doctor', medication.doctor!),
                if (medication.doctor != null && medication.pharmacy != null)
                  SharedWidgets.verticalSpace(),
                if (medication.pharmacy != null)
                  _buildInfoRow('Pharmacy', medication.pharmacy!),
              ],
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
          ],

          // Schedule information card
          SharedWidgets.basicCard(
            context: context,
            title: medication.medicationType == MedicationType.patch
                ? 'Change Schedule'
                : 'Schedule',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.getIcon('calendar')),
                  SharedWidgets.verticalSpace(),
                  Expanded(
                    child: Text(
                        DateTimeFormatter.formatDaysOfWeek(
                            medication.daysOfWeek),
                        style: AppTextStyles.bodyLarge),
                  ),
                ],
              ),
              SharedWidgets.verticalSpace(AppTheme.spacing * 2),
              // Sort and display all time slots chronologically
              ...(() {
                // Create a sorted copy of all time slots
                final sortedTimes = List<DateTime>.from(medication.timeOfDay);
                sortedTimes.sort((a, b) {
                  final aTimeStr = DateTimeFormatter.formatTimeToAMPM(
                      TimeOfDay.fromDateTime(a));
                  final bTimeStr = DateTimeFormatter.formatTimeToAMPM(
                      TimeOfDay.fromDateTime(b));
                  return DateTimeFormatter.compareTimeSlots(aTimeStr, bTimeStr);
                });

                // Convert each time slot to a UI element
                return sortedTimes.map((time) {
                  final timeOfDay = TimeOfDay.fromDateTime(time);
                  final timeStr = DateTimeFormatter.formatTimeToAMPM(timeOfDay);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(DateTimeFormatter.getTimeIcon(timeStr)),
                        SharedWidgets.verticalSpace(AppTheme.spacing),
                        Text(timeStr, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }).toList();
              })(),
            ],
          ),
          SharedWidgets.verticalSpace(AppTheme.cardSpacing),

          // Injection details card - only shown for injection medications
          if (medication.medicationType == MedicationType.injection &&
              medication.injectionDetails != null) ...[
            SharedWidgets.basicCard(
              context: context,
              title: 'Injection Details',
              children: [
                _buildInfoRow(
                    'Type',
                    _getInjectionSubtypeText(
                        medication.injectionDetails!.subtype)),
                SharedWidgets.verticalSpace(AppTheme.spacing * 2),

                // Syringes section
                Text('Syringes', style: AppTextStyles.titleSmall),
                SharedWidgets.verticalSpace(),
                _buildInfoRow('Type', medication.injectionDetails!.syringeType),
                SharedWidgets.verticalSpace(),
                if (medication.injectionDetails!.syringeCount > 0)
                  _buildInfoRow('Remaining / Refill',
                      '${medication.injectionDetails!.syringeCount} / ${medication.injectionDetails!.syringeRefills.toString()}'),
                SharedWidgets.verticalSpace(AppTheme.spacing * 2),

                // Drawing Needles section
                Text('Drawing Needles', style: AppTextStyles.titleSmall),
                SharedWidgets.verticalSpace(),
                _buildInfoRow(
                    'Type', medication.injectionDetails!.drawingNeedleType),
                SharedWidgets.verticalSpace(),
                if (medication.injectionDetails!.drawingNeedleCount > 0 &&
                    medication.injectionDetails!.drawingNeedleRefills > 0)
                  _buildInfoRow('Remaining / Refill',
                      '${medication.injectionDetails!.drawingNeedleCount} / ${medication.injectionDetails!.drawingNeedleRefills.toString()}'),
                SharedWidgets.verticalSpace(AppTheme.spacing * 2),

                // Injecting Needles section
                Text('Injecting Needles', style: AppTextStyles.titleSmall),
                SharedWidgets.verticalSpace(),
                _buildInfoRow(
                    'Type', medication.injectionDetails!.injectingNeedleType),
                SharedWidgets.verticalSpace(),
                if (medication.injectionDetails!.injectingNeedleCount > 0 &&
                    medication.injectionDetails!.injectingNeedleRefills > 0)
                  _buildInfoRow('Remaining / Refill',
                      '${medication.injectionDetails!.injectingNeedleCount} / ${medication.injectionDetails!.injectingNeedleRefills.toString()}'),

                // Injection site notes
                if (medication
                    .injectionDetails!.injectionSiteNotes.isNotEmpty) ...[
                  SharedWidgets.verticalSpace(AppTheme.spacing * 2),
                  Text('Site Notes', style: AppTextStyles.titleSmall),
                  SharedWidgets.verticalSpace(),
                  Text(medication.injectionDetails!.injectionSiteNotes),
                ],
              ],
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
          ],

          // Notes card - only shown if notes exist
          if (medication.notes?.isNotEmpty == true) ...[
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            SharedWidgets.basicCard(
              context: context,
              title: 'Notes',
              children: [
                Text(medication.notes!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Helper to build consistent info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  /// Get the appropriate icon based on medication type and subtype
  Widget _buildMedicationTypeIcon() {
    switch (medication.medicationType) {
      case MedicationType.oral:
        return Icon(AppIcons.getOutlined('medication'));
      case MedicationType.injection:
        return Icon(AppIcons.getOutlined('vaccine'));
      case MedicationType.topical:
        return Icon(AppIcons.getOutlined('topical'));
      case MedicationType.patch:
        return Icon(AppIcons.getOutlined('patch'));
    }
  }

  /// Get a text description of the medication type and subtype
  String _getMedicationTypeText() {
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
            subtypeText = '';
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
            subtypeText = '';
            break;
        }
        return 'Topical${subtypeText.isNotEmpty ? ' - $subtypeText' : ''}';

      case MedicationType.patch:
        return 'Patch';
    }
  }

  /// Get a text description of the injection subtype
  String _getInjectionSubtypeText(InjectionSubtype subtype) {
    switch (subtype) {
      case InjectionSubtype.intravenous:
        return 'Intravenous (IV)';
      case InjectionSubtype.intramuscular:
        return 'Intramuscular (IM)';
      case InjectionSubtype.subcutaneous:
        return 'Subcutaneous (SC)';
    }
  }

  /// Show confirmation dialog before deleting medication
  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.goBackWithResult(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => NavigationService.goBackWithResult(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await ref
          .read(medicationStateProvider.notifier)
          .deleteMedication(medication.id);
      if (context.mounted) {
        NavigationService.goHome(context);
      }
    }
  }
}
