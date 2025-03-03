//
//  medication_list_screen.dart
//  Screen that displays user medications in a list with sticky headers
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nokken/src/core/utils/get_icons_colors.dart';
import 'package:nokken/src/features/medication_tracker/models/medication.dart';
import 'package:nokken/src/features/medication_tracker/providers/medication_state.dart';
import 'package:nokken/src/core/services/navigation/navigation_service.dart';
import 'package:nokken/src/core/utils/date_time_formatter.dart';
import 'package:nokken/src/core/theme/shared_widgets.dart';
import 'package:nokken/src/core/theme/app_icons.dart';
import 'package:nokken/src/core/theme/app_theme.dart';

/// This widget adds a sticky header decorator for each medication type section
class MedicationSectionWithStickyHeader extends StatelessWidget {
  final String title;
  final List<Medication> medications;
  final MedicationType type;

  const MedicationSectionWithStickyHeader({
    super.key,
    required this.title,
    required this.medications,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = GetIconsColors.getMedicationColor(type);

    return SliverStickyHeader(
      header: Container(
        color: AppColors.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            // Icon based on medication type
            GetIconsColors.getMedicationIconWithColor(type),
            SharedWidgets.horizontalSpace(),
            // Section title
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: typeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Count badge
            SharedWidgets.horizontalSpace(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${medications.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              MedicationListTile(medication: medications[index]),
          childCount: medications.length,
        ),
      ),
    );
  }
}

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes to medication data using the grouped provider
    final groupedMedications = ref.watch(groupedMedicationTypeProvider);
    final isLoading = ref.watch(medicationsLoadingProvider);
    final error = ref.watch(medicationsErrorProvider);
    final needsRefill = ref.watch(medicationsByNeedRefillProvider);

// Check if there are any medications
    final bool hasMedications = groupedMedications['oral']!.isNotEmpty ||
        groupedMedications['injection']!.isNotEmpty ||
        groupedMedications['topical']!.isNotEmpty ||
        groupedMedications['patch']!.isNotEmpty;

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
                padding: AppTheme.standardCardPadding,
                child: Row(
                  children: [
                    Icon(
                      AppIcons.getIcon('warning'),
                      color: AppColors.error,
                    ),
                    SharedWidgets.horizontalSpace(),
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
                      AppIcons.getIcon('error'),
                      color: AppColors.error,
                    ),
                    SharedWidgets.horizontalSpace(),
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
                  : !hasMedications
                      ? _buildEmptyState(context)
                      : CustomScrollView(
                          slivers: [
                            // Only add sections that have medications
                            if (groupedMedications['oral']!.isNotEmpty)
                              MedicationSectionWithStickyHeader(
                                title: 'Oral',
                                medications: groupedMedications['oral']!,
                                type: MedicationType.oral,
                              ),

                            if (groupedMedications['topical']!.isNotEmpty)
                              MedicationSectionWithStickyHeader(
                                title: 'Topical',
                                medications: groupedMedications['topical']!,
                                type: MedicationType.topical,
                              ),

                            if (groupedMedications['patch']!.isNotEmpty)
                              MedicationSectionWithStickyHeader(
                                title: 'Patch',
                                medications: groupedMedications['patch']!,
                                type: MedicationType.patch,
                              ),

                            if (groupedMedications['injection']!.isNotEmpty)
                              MedicationSectionWithStickyHeader(
                                title: 'Injectable',
                                medications: groupedMedications['injection']!,
                                type: MedicationType.injection,
                              ),

                            // If we need spacing at the bottom, add a sliver padding
                            const SliverPadding(
                              padding:
                                  EdgeInsets.only(bottom: 80), // Space for FAB
                            ),
                          ],
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
            AppIcons.getOutlined('medication'),
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
          leading:
              GetIconsColors.getMedicationIconCirlce(medication.medicationType),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SharedWidgets.verticalSpace(),
              Row(
                children: [
                  Text(_getTypeBadgeText()),
                  if (medication.currentQuantity != 0 ||
                      medication.refillThreshold != 0) ...[
                    const Text(' • '),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                    ),
                    Text('${medication.currentQuantity}'),
                  ],
                ],
              ),
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

  /// Get a short text description for the medication type badge
  String _getTypeBadgeText() {
    switch (medication.medicationType) {
      case MedicationType.oral:
        switch (medication.oralSubtype) {
          case OralSubtype.tablets:
            return 'Tablets';
          case OralSubtype.capsules:
            return 'Capsules';
          case OralSubtype.drops:
            return 'Drops';
          case null:
            return 'Oral';
        }

      case MedicationType.injection:
        switch (medication.injectionDetails?.subtype) {
          case InjectionSubtype.intravenous:
            return 'IV';
          case InjectionSubtype.intramuscular:
            return 'IM';
          case InjectionSubtype.subcutaneous:
            return 'SC';
          case null:
            return 'Injection';
        }

      case MedicationType.topical:
        switch (medication.topicalSubtype) {
          case TopicalSubtype.gel:
            return 'Gel';
          case TopicalSubtype.cream:
            return 'Cream';
          case TopicalSubtype.spray:
            return 'Spray';
          case null:
            return 'Topical';
        }

      case MedicationType.patch:
        return 'Patch';
    }
  }
}
