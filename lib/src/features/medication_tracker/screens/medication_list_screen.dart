//
//  medication_list_screen.dart
//  Screen that displays user medications in a list
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes to medication data
    final medications = ref.watch(sortedMedicationsProvider);
    final isLoading = ref.watch(medicationsLoadingProvider);
    final error = ref.watch(medicationsErrorProvider);
    final needsRefill = ref.watch(medicationsByNeedRefillProvider);

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
            // Refill Alert Section - shown only when medications need refill
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
                  ],
                ),
              ),

            // Error Display - shown only when there's an error
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

            // Main Content Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : medications.isEmpty
                      ? _buildEmptyState(context)
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
      // FAB for adding new medications
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationService.goToMedicationAddEdit(context),
        child: Icon(AppIcons.getIcon('add')),
      ),
    );
  }

  /// Builds the empty state view when no medications exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            onPressed: () => NavigationService.goToMedicationAddEdit(context),
            child: const Text('Add Medication'),
          ),
        ],
      ),
    );
  }
}

/// List tile for displaying a medication in the list
class MedicationListTile extends StatelessWidget {
  final Medication medication;

  const MedicationListTile({
    super.key,
    required this.medication,
  });

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
              Text(DateTimeFormatter.formatMedicationFrequencyDosage(
                  medication)),
              // Show refill indicator if needed
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
}
