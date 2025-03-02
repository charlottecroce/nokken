//
//  bloodwork_list_screen.dart
//  Screen that displays user's bloodwork records in a list
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/core/services/navigation/navigation_service.dart';
import 'package:nokken/src/core/theme/shared_widgets.dart';
import 'package:nokken/src/core/theme/app_icons.dart';
import 'package:nokken/src/core/theme/app_theme.dart';
import 'package:nokken/src/core/utils/date_time_formatter.dart';
import 'package:nokken/src/core/utils/appointment_utils.dart';

/// This widget adds a sticky header decorator for each section
class SectionWithStickyHeader extends StatelessWidget {
  final String title;
  final List<Bloodwork> records;

  const SectionWithStickyHeader({
    super.key,
    required this.title,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    // Return a SliverToBoxAdapter instead of SizedBox.shrink for empty records
    if (records.isEmpty) {
      return SliverToBoxAdapter(child: const SizedBox());
    }

    // Determine icon and color based on section title
    IconData sectionIcon;
    Color sectionColor;

    switch (title) {
      case 'Today':
        sectionIcon = AppIcons.getIcon('today');
        sectionColor = AppTheme.greenDark;
        break;
      case 'Upcoming':
        sectionIcon = AppIcons.getIcon('event');
        sectionColor = Colors.blue;
        break;
      case 'Past':
      default:
        sectionIcon = AppIcons.getIcon('history');
        sectionColor = Colors.grey;
        break;
    }

    return SliverStickyHeader(
      header: Container(
        color: AppColors.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            // Icon based on section
            Icon(
              sectionIcon,
              size: 20,
              color: sectionColor,
            ),
            SharedWidgets.horizontalSpace(),
            // Section title
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: sectionColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Count badge
            SharedWidgets.horizontalSpace(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sectionColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${records.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: sectionColor,
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
        groupedRecords['today']!.isNotEmpty ||
        groupedRecords['past']!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(AppIcons.getIcon('analytics')),
            onPressed: () => NavigationService.goToBloodLevelList(context),
            tooltip: 'View Hormone Levels',
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
                  : !hasRecords
                      ? _buildEmptyState(context)
                      : CustomScrollView(
                          slivers: [
                            // Today section with sticky header
                            SectionWithStickyHeader(
                              title: 'Today',
                              records: groupedRecords['today']!,
                            ),

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
            AppIcons.getOutlined('event_note'),
            size: 64,
            color: AppColors.secondary,
          ),
          SharedWidgets.verticalSpace(),
          Text(
            'No appointments yet',
            style: AppTheme.titleLarge,
          ),
          SharedWidgets.verticalSpace(),
          ElevatedButton(
            onPressed: () => NavigationService.goToBloodworkAddEdit(context),
            child: const Text('Add Appointment'),
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

  @override
  Widget build(BuildContext context) {
    final isFutureDate = _isDateInFuture();
    // Format the time for display
    final timeOfDay = TimeOfDay.fromDateTime(bloodwork.date);
    final timeStr = DateTimeFormatter.formatTimeToAMPM(timeOfDay);
    final timeIcon = DateTimeFormatter.getTimeIcon(timeStr);

    // Use the AppointmentUtils helper for appointment details
    final appointmentTypeText =
        AppointmentUtils.getAppointmentTypeText(bloodwork.appointmentType);
    final appointmentTypeIcon =
        AppointmentUtils.getAppointmentTypeIcon(bloodwork.appointmentType);
    final appointmentTypeColor =
        AppointmentUtils.getAppointmentTypeColor(bloodwork.appointmentType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: AppTheme.standardCardPadding,
        title: Row(
          children: [
            Flexible(
              // Added Flexible to prevent overflow
              child: Text(
                DateTimeFormatter.formatDateMMMDDYYYY(bloodwork.date),
                style: AppTextStyles.titleMedium,
                overflow:
                    TextOverflow.ellipsis, // Added ellipsis for long dates
              ),
            ),
            if (isFutureDate) ...[
              SharedWidgets.horizontalSpace(),
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
                SharedWidgets.horizontalSpace(6),
                Flexible(
                  // Added Flexible to prevent overflow
                  child: Text(
                    appointmentTypeText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: appointmentTypeColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis, // Added ellipsis
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
                SharedWidgets.verticalSpace(6),
                Flexible(
                  // Added Flexible to prevent overflow
                  child: Text(
                    timeStr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: appointmentTypeColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis, // Added ellipsis
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
                    AppIcons.getOutlined('location'),
                    size: 16,
                    color: Colors.grey,
                  ),
                  SharedWidgets.verticalSpace(6),
                  Flexible(
                    child: Text(
                      bloodwork.location!,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    AppIcons.getIcon('profile'),
                    size: 16,
                    color: Colors.grey,
                  ),
                  SharedWidgets.verticalSpace(6),
                  Flexible(
                    child: Text(
                      bloodwork.doctor!,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            // Otherwise show hormone levels if bloodwork type
            else if (bloodwork.appointmentType ==
                AppointmentType.bloodwork) ...[
              // Display hormone readings if available
              if (bloodwork.hormoneReadings.isNotEmpty)
                ...bloodwork.hormoneReadings.take(2).map((reading) => Text(
                    '${reading.name}: ${reading.value.toStringAsFixed(1)} ${reading.unit}',
                    overflow: TextOverflow.ellipsis)), // Added ellipsis

              // Show count if there are more readings
              if (bloodwork.hormoneReadings.length > 2)
                Text('...and ${bloodwork.hormoneReadings.length - 2} more',
                    style: AppTextStyles.bodySmall),
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
        trailing: Icon(AppIcons.getIcon('chevron_right')),
      ),
    );
  }
}
