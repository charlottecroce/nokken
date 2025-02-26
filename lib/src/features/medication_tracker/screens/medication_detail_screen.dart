//
//  medication_detail_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';

class MedicationDetailScreen extends ConsumerWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  String _formatDays(Set<String> days) {
    if (days.length == 7 && DateConstants.orderedDays.every(days.contains)) {
      return 'Everyday';
    }

    final sortedDays = days.toList()
      ..sort((a, b) => DateConstants.orderedDays
          .indexOf(a)
          .compareTo(DateConstants.orderedDays.indexOf(b)));

    return sortedDays.map((day) => DateConstants.dayNames[day]).join(', ');
  }

  String _formatFrequency() {
    if (medication.medicationType == MedicationType.injection) {
      return 'every week';
    }
    if (medication.injectionDetails?.frequency == InjectionFrequency.biweekly) {
      return 'Once every 2 weeks';
    }
    String frequencyText = medication.frequency == 1
        ? 'once'
        : medication.frequency == 2
            ? 'twice'
            : '${medication.frequency} times';

    return '$frequencyText a day';
  }

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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => NavigationService.goToMedicationAddEdit(context,
                medication: medication),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: AppTheme.standardCardPadding,
        children: [
          if (medication.needsRefill())
            Card(
              color: AppColors.errorContainer,
              child: Padding(
                padding: AppTheme.standardCardPadding,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
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
          Card(
            child: Padding(
              padding: AppTheme.standardCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (medication.medicationType == MedicationType.oral)
                        Icon(AppIcons.getIcon('medication'))
                      else
                        Icon(AppIcons.getIcon('vaccine')),
                      SharedWidgets.verticalSpace(),
                      Text(medication.name, style: AppTextStyles.titleLarge),
                    ],
                  ),
                  SharedWidgets.verticalSpace(AppTheme.cardPadding),
                  _buildInfoRow('Dosage', medication.dosage),
                  SharedWidgets.verticalSpace(),
                  _buildInfoRow('Frequency', _formatFrequency()),
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
          SharedWidgets.basicCard(
            context: context,
            title: 'Schedule',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.getIcon('calendar')),
                  SharedWidgets.verticalSpace(),
                  Expanded(
                    child: Text(_formatDays(medication.daysOfWeek),
                        style: AppTextStyles.bodyLarge),
                  ),
                ],
              ),
              SharedWidgets.verticalSpace(AppTheme.spacing * 2),
              ...medication.timeOfDay.map((time) {
                final timeStr = TimeOfDay.fromDateTime(time).format(context);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      SharedWidgets.verticalSpace(AppTheme.spacing),
                      Text(timeStr, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          if (medication.medicationType == MedicationType.injection &&
              medication.injectionDetails != null) ...[
            SharedWidgets.basicCard(
              context: context,
              title: 'Srynges',
              children: [
                _buildInfoRow('Drawing Needle',
                    medication.injectionDetails!.drawingNeedleType),
                SharedWidgets.verticalSpace(),
                if (medication.injectionDetails!.drawingNeedleCount > 0 &&
                    medication.injectionDetails!.drawingNeedleRefills > 0)
                  _buildInfoRow('Remaining / Refill',
                      '${medication.injectionDetails!.drawingNeedleCount} / ${medication.injectionDetails!.drawingNeedleRefills.toString()}'),
                SharedWidgets.verticalSpace(AppTheme.spacing * 2),
                _buildInfoRow('Injecting Needle',
                    medication.injectionDetails!.injectingNeedleType),
                SharedWidgets.verticalSpace(),
                if (medication.injectionDetails!.injectingNeedleCount > 0 &&
                    medication.injectionDetails!.injectingNeedleRefills > 0)
                  _buildInfoRow('Remaining / Refill',
                      '${medication.injectionDetails!.injectingNeedleCount} / ${medication.injectionDetails!.injectingNeedleRefills.toString()}'),
                if (medication
                        .injectionDetails!.injectionSiteNotes.isNotEmpty ==
                    true) ...[
                  SharedWidgets.verticalSpace(AppTheme.spacing * 2),
                  Text(medication.injectionDetails!.injectionSiteNotes),
                ],
              ],
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
          ],
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

  Widget _buildInfoRow(String label, String value) {
    ;
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
