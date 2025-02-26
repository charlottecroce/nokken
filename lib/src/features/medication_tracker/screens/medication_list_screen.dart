//
//  medication_list_screen.dart
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(sortedMedicationsProvider);
    final isLoading = ref.watch(medicationsLoadingProvider);
    final error = ref.watch(medicationsErrorProvider);
    final needsRefill = ref.watch(medicationsByNeedRefillProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(medicationStateProvider.notifier).loadMedications(),
        child: Column(
          children: [
            // Refill Alert Section
            if (needsRefill.isNotEmpty)
              Container(
                color: AppColors.errorContainer.withAlpha(25),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${needsRefill.length} medication${needsRefill.length != 1 ? 's' : ''} need${needsRefill.length == 1 ? 's' : ''} refill',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // TextButton(
                    //  onPressed: () {
                    // Show refill details screen
                    //   },
                    //  child: const Text('View All'),
                    // ),
                  ],
                ),
              ),

            // Error Display
            if (error != null)
              Container(
                color: AppColors.errorContainer,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 64,
                                color: AppColors.secondary,
                              ),
                              SharedWidgets.verticalSpace(),
                              Text(
                                'No medications yet',
                                style: AppTheme.titleLarge,
                              ),
                              SharedWidgets.verticalSpace(),
                              ElevatedButton(
                                onPressed: () =>
                                    NavigationService.goToMedicationAddEdit(
                                        context),
                                child: const Text('Add Medication'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final medication = medications[index];
                            return MedicationListTile(medication: medication);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationService.goToMedicationAddEdit(context),
        child: Icon(AppIcons.getIcon('add')),
      ),
    );
  }
}

class MedicationListTile extends StatelessWidget {
  final Medication medication;

  const MedicationListTile({
    super.key,
    required this.medication,
  });

  //
  // Medication Card
  //
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
          contentPadding: AppTheme.standardCardPadding,
          title: Text(medication.name, style: AppTextStyles.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SharedWidgets.verticalSpace(),
              Text(formatMedicationFrequency()),
              if (medication.needsRefill()) ...[
                SharedWidgets.verticalSpace(),
                Container(
                  padding: AppTheme.standardCardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                  ),
                  child: Text(
                    'Refill needed',
                    style: AppTextStyles.error,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => NavigationService.goToMedicationDetails(context,
              medication: medication)),
    );
  }

// create the text under medication name
  String formatMedicationFrequency() {
    // cases for once/twice/three times
    String frequencyText = medication.frequency == 1
        ? 'once'
        : medication.frequency == 2
            ? 'twice'
            : '${medication.frequency} times';

    if (medication.medicationType == MedicationType.oral) {
      if (medication.daysOfWeek.isEmpty || medication.daysOfWeek.length == 7) {
        return 'Take ${medication.dosage} $frequencyText daily, everyday';
      } else {
        return 'Take ${medication.dosage} $frequencyText daily, on ${medication.daysOfWeek.join(', ')}';
      }
    } else {
      return 'Inject ${medication.dosage} on ${medication.daysOfWeek.join(', ')}';
    }
  }
}
