//
//  bloodwork_list_screen.dart
//  Screen that displays user's bloodwork records in a list
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';

/// This widget adds a sticky header decorator for each section
class SectionWithStickyHeader extends StatelessWidget {
  final String title;
  final List<Bloodwork> records;

  const SectionWithStickyHeader({
    Key? key,
    required this.title,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    return SliverStickyHeader(
      header: Container(
        color: AppColors.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            // Icon based on section
            Icon(
              title == 'Upcoming' ? Icons.event : Icons.history,
              size: 20,
              color: title == 'Upcoming' ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            // Section title
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: title == 'Upcoming' ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Count badge
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: title == 'Upcoming'
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${records.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: title == 'Upcoming' ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => BloodworkListTile(bloodwork: records[index]),
          childCount: records.length,
        ),
      ),
    );
  }
}

/// Main bloodwork list screen with sections
class BloodworkListScreen extends ConsumerWidget {
  const BloodworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes to bloodwork data using the grouped provider
    final groupedRecords = ref.watch(groupedBloodworkProvider);
    final isLoading = ref.watch(bloodworkLoadingProvider);
    final error = ref.watch(bloodworkErrorProvider);

    // Check if there are any records at all
    final bool hasRecords = groupedRecords['upcoming']!.isNotEmpty ||
        groupedRecords['past']!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => NavigationService.goToBloodworkGraph(context),
            tooltip: 'View Hormone Graph',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(bloodworkStateProvider.notifier).loadBloodwork(),
        child: Column(
          children: [
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
                  : !hasRecords
                      ? _buildEmptyState(context)
                      : CustomScrollView(
                          slivers: [
                            // Upcoming section with sticky header
                            SectionWithStickyHeader(
                              title: 'Upcoming',
                              records: groupedRecords['upcoming']!,
                            ),

                            // Past section with sticky header
                            SectionWithStickyHeader(
                              title: 'Past',
                              records: groupedRecords['past']!,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      // FAB for adding new bloodwork records
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationService.goToBloodworkAddEdit(context),
        child: Icon(AppIcons.getIcon('add')),
      ),
    );
  }

  /// Builds the empty state view when no records exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: AppColors.secondary,
          ),
          SharedWidgets.verticalSpace(),
          Text(
            'No medical records yet',
            style: AppTheme.titleLarge,
          ),
          SharedWidgets.verticalSpace(),
          ElevatedButton(
            onPressed: () => NavigationService.goToBloodworkAddEdit(context),
            child: const Text('Add Medical Record'),
          ),
        ],
      ),
    );
  }
}

/// List tile for displaying a bloodwork record in the list
class BloodworkListTile extends StatelessWidget {
  final Bloodwork bloodwork;

  const BloodworkListTile({
    super.key,
    required this.bloodwork,
  });

  /// Check if date is in the future
  bool _isDateInFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate =
        DateTime(bloodwork.date.year, bloodwork.date.month, bloodwork.date.day);
    return recordDate.isAfter(today);
  }

  /// Get appointment type text to display
  String _getAppointmentTypeText() {
    switch (bloodwork.appointmentType) {
      case AppointmentType.bloodwork:
        return 'Lab Results';
      case AppointmentType.appointment:
        return 'Appointment';
      case AppointmentType.surgery:
        return 'Surgery';
      default:
        return 'Medical Record';
    }
  }

  /// Get appointment type icon
  IconData _getAppointmentTypeIcon() {
    switch (bloodwork.appointmentType) {
      case AppointmentType.bloodwork:
        return Icons.science_outlined;
      case AppointmentType.appointment:
        return Icons.medical_services_outlined;
      case AppointmentType.surgery:
        return Icons.medical_information_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  /// Get appointment type color -- in future, map to AppTheme
  Color _getAppointmentTypeColor() {
    switch (bloodwork.appointmentType) {
      case AppointmentType.bloodwork:
        return Colors.red;
      case AppointmentType.appointment:
        return Colors.blue;
      case AppointmentType.surgery:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFutureDate = _isDateInFuture();
    // Format the time for display
    final timeOfDay = TimeOfDay.fromDateTime(bloodwork.date);
    final timeStr = DateTimeFormatter.formatTimeToAMPM(timeOfDay);
    final timeIcon = DateTimeFormatter.getTimeIcon(timeStr);

    final appointmentTypeText = _getAppointmentTypeText();
    final appointmentTypeIcon = _getAppointmentTypeIcon();
    final appointmentTypeColor = _getAppointmentTypeColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: AppTheme.standardCardPadding,
        title: Row(
          children: [
            Text(
              DateTimeFormatter.formatDateMMMDDYYYY(bloodwork.date),
              style: AppTextStyles.titleMedium,
            ),
            if (isFutureDate) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withAlpha(40)),
                ),
                child: Text(
                  'Scheduled',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SharedWidgets.verticalSpace(),
            // Display appointment type
            Row(
              children: [
                Icon(
                  appointmentTypeIcon,
                  size: 16,
                  color: appointmentTypeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  appointmentTypeText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: appointmentTypeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SharedWidgets.verticalSpace(4),
            // Display appointment time with icon
            Row(
              children: [
                Icon(
                  timeIcon,
                  size: 16,
                  color: appointmentTypeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: appointmentTypeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SharedWidgets.verticalSpace(4),

            // Display location if available
            if (bloodwork.location?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bloodwork.location!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              SharedWidgets.verticalSpace(2),
            ],

            // Display doctor if available
            if (bloodwork.doctor?.isNotEmpty == true) ...[
              Row(
                children: [
                  Icon(
                    Icons.person_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    bloodwork.doctor!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              SharedWidgets.verticalSpace(2),
            ],

            // If future date, show scheduled message
            if (isFutureDate)
              Text(
                'Scheduled',
                style: AppTextStyles.bodyMedium,
              )
            // Otherwise show hormone levels if available and if this is bloodwork
            else if (bloodwork.appointmentType ==
                AppointmentType.bloodwork) ...[
              if (bloodwork.estrogen != null)
                Text(
                    'Estrogen: ${bloodwork.estrogen!.toStringAsFixed(1)} pg/mL'),
              if (bloodwork.testosterone != null)
                Text(
                    'Testosterone: ${bloodwork.testosterone!.toStringAsFixed(1)} ng/dL'),
            ],
            // Display notes if any
            if (bloodwork.notes?.isNotEmpty == true) ...[
              SharedWidgets.verticalSpace(),
              Text(
                'Notes: ${bloodwork.notes}',
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        onTap: () => NavigationService.goToBloodworkAddEdit(
          context,
          bloodwork: bloodwork,
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
