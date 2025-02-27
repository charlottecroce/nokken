//
//  add_edit_medication_screen.dart
//  Screen that handles both adding new medications and editing existing ones
//  Uses a form with multiple sections for different medication properties
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/services/validation_service.dart';
import 'package:nokken/src/shared/constants/date_constants.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import '../models/medication.dart';
import '../providers/medication_state.dart';

class AddEditMedicationScreen extends ConsumerStatefulWidget {
  final Medication? medication;

  const AddEditMedicationScreen({
    super.key,
    this.medication,
  });

  @override
  ConsumerState<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState
    extends ConsumerState<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers that need disposal
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  // State variables
  late MedicationType _medicationType;
  late DateTime _startDate;
  late int _frequency;
  late List<TimeOfDay> _times;
  late Set<String> _selectedDays;
  late int _currentQuantity;
  late int _refillThreshold;
  late InjectionDetails? _injectionDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  /// Initialize all form fields with either existing medication data or defaults
  void _initializeFields() {
    // Initialize controllers
    _nameController =
        TextEditingController(text: widget.medication?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.medication?.dosage ?? '');
    _notesController =
        TextEditingController(text: widget.medication?.notes ?? '');

    // Initialize medication type and related fields
    _medicationType = widget.medication?.medicationType ?? MedicationType.oral;
    _injectionDetails = _initializeInjectionDetails();

    // Initialize schedule related fields
    _startDate = widget.medication?.startDate ?? DateTime.now();
    _frequency = widget.medication?.frequency ?? 1;
    _times = _initializeTimes();
    _selectedDays = widget.medication?.daysOfWeek ??
        <String>{'Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'};

    // Initialize inventory related fields
    _currentQuantity = widget.medication?.currentQuantity ?? 0;
    _refillThreshold = widget.medication?.refillThreshold ?? 0;
  }

  /// Initialize time slots from existing medication or default to current time
  List<TimeOfDay> _initializeTimes() {
    if (widget.medication != null) {
      return widget.medication!.timeOfDay
          .map((dt) => TimeOfDay.fromDateTime(dt))
          .toList();
    }
    return [TimeOfDay.now()];
  }

  /// Initialize injection details if applicable
  InjectionDetails? _initializeInjectionDetails() {
    if (_medicationType == MedicationType.injection) {
      return widget.medication?.injectionDetails ??
          InjectionDetails(
            drawingNeedleType: '',
            drawingNeedleCount: 0,
            drawingNeedleRefills: 0,
            injectingNeedleType: '',
            injectingNeedleCount: 0,
            injectingNeedleRefills: 0,
            injectionSiteNotes: '',
            frequency: InjectionFrequency.weekly,
          );
    }
    return null;
  }

  /// Handle medication type change (oral/injection)
  /// Resets relevant fields according to the type
  void _handleTypeChange(MedicationType type) {
    setState(() {
      _medicationType = type;
      if (type == MedicationType.injection) {
        _frequency = 1;
        _selectedDays = {'Su'};
        _injectionDetails ??= _initializeInjectionDetails();
      } else {
        _injectionDetails = null;
        _selectedDays = {'Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'};
      }
    });
  }

  // Clean up controllers to prevent memory leaks
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save or update medication data
  Future<void> _saveMedication() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Create medication object from form data
      final medication = Medication(
        id: widget.medication?.id, // null for new, existing id for updates
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        startDate: _startDate,
        frequency: _frequency,
        timeOfDay: _times.map((time) {
          final now = DateTime.now();
          return DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );
        }).toList(),
        daysOfWeek: _selectedDays,
        currentQuantity: _currentQuantity,
        refillThreshold: _refillThreshold,
        notes: _notesController.text.trim(),
        medicationType: _medicationType,
        injectionDetails: _injectionDetails,
      );

      // If medication is null, we're adding new
      // Otherwise, we're updating existing
      if (widget.medication == null) {
        await ref
            .read(medicationStateProvider.notifier)
            .addMedication(medication);
      } else {
        await ref
            .read(medicationStateProvider.notifier)
            .updateMedication(medication);
      }

      // Return to details screen
      if (mounted) {
        NavigationService.goToMedicationDetails(context,
            medication: medication);
      }
    } catch (e) {
      // Show error in snackbar if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Update injection details when fields change
  void _updateInjectionDetails({
    String? drawingNeedleType,
    int? drawingNeedleCount,
    int? drawingNeedleRefills,
    String? injectingNeedleType,
    int? injectingNeedleCount,
    int? injectingNeedleRefills,
    String? injectionSiteNotes,
    InjectionFrequency? frequency,
  }) {
    if (_injectionDetails == null) return;

    setState(() {
      _injectionDetails = InjectionDetails(
        drawingNeedleType:
            drawingNeedleType ?? _injectionDetails!.drawingNeedleType,
        drawingNeedleCount:
            drawingNeedleCount ?? _injectionDetails!.drawingNeedleCount,
        drawingNeedleRefills:
            drawingNeedleRefills ?? _injectionDetails!.drawingNeedleRefills,
        injectingNeedleType:
            injectingNeedleType ?? _injectionDetails!.injectingNeedleType,
        injectingNeedleCount:
            injectingNeedleCount ?? _injectionDetails!.injectingNeedleCount,
        injectingNeedleRefills:
            injectingNeedleRefills ?? _injectionDetails!.injectingNeedleRefills,
        injectionSiteNotes:
            injectionSiteNotes ?? _injectionDetails!.injectionSiteNotes,
        frequency: frequency ?? _injectionDetails!.frequency,
      );
    });

    // Ensure frequency is 1 when biweekly is selected.
    // We could have twice a week, every other week, but that's confusing idk who injects like that
    if (frequency == InjectionFrequency.biweekly && _frequency != 1) {
      _frequency = 1;
      _times = _adjustTimesList(_times, 1);
    }
  }

  /// Handle frequency change (times per day)
  void _handleFrequencyChange(int newFrequency) {
    setState(() {
      _frequency = newFrequency;
      _times = _adjustTimesList(_times, newFrequency);
    });
  }

  /// Adjust the time slots list when frequency changes
  List<TimeOfDay> _adjustTimesList(
      List<TimeOfDay> currentTimes, int newFrequency) {
    if (newFrequency > currentTimes.length) {
      // Add new time slots if frequency increases
      return [
        ...currentTimes,
        ...List.generate(
          newFrequency - currentTimes.length,
          (_) => TimeOfDay.now(),
        )
      ];
    }
    // Remove excess time slots if frequency decreases
    return currentTimes.sublist(0, newFrequency);
  }

  /// Handle changes to the selected days of the week
  void _handleDaysChange(Set<String> newDays) {
    setState(() {
      _selectedDays = newDays;
    });
  }

  /// Handle changes to individual time slots
  void _handleTimeChange(int index, TimeOfDay newTime) {
    setState(() {
      _times[index] = newTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Show different title based on add/edit mode
        title: Text(
            widget.medication == null ? 'Add Medication' : 'Edit Medication'),
        actions: [
          // Show loading indicator or save button
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: AppTheme.standardCardPadding,
                    child: CircularProgressIndicator(),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveMedication,
                ),
        ],
      ),
      // Main form layout using ListView for scrolling
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppTheme.standardCardPadding,
          children: [
            // Basic information section (name, dosage)
            BasicInfoSection(
              nameController: _nameController,
              dosageController: _dosageController,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Medication type section (oral/injection)
            MedicationTypeSection(
              medicationType: _medicationType,
              onTypeChanged: _handleTypeChange,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Injection details section (only shown for injectable medications)
            if (_medicationType == MedicationType.injection)
              InjectionDetailsSection(
                injectionDetails: _injectionDetails!,
                onDetailsChanged: _updateInjectionDetails,
              ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Timing section (frequency, days, time slots)
            TimingSection(
              selectedStartDate: _startDate,
              onStartDateChanged: (date) => setState(() => _startDate = date),
              frequency: _frequency,
              times: _times,
              selectedDays: _selectedDays,
              onFrequencyChanged: _handleFrequencyChange,
              onTimeChanged: _handleTimeChange,
              onDaysChanged: _handleDaysChange,
              isEveryTwoWeeks: _medicationType == MedicationType.injection &&
                  _injectionDetails?.frequency == InjectionFrequency.biweekly,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Inventory section (quantities and refill threshold)
            InventorySection(
              currentQuantity: _currentQuantity,
              refillThreshold: _refillThreshold,
              onQuantityChanged: (value) =>
                  setState(() => _currentQuantity = value),
              onThresholdChanged: (value) =>
                  setState(() => _refillThreshold = value),
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Notes section
            NotesSection(controller: _notesController),
          ],
        ),
      ),
    );
  }
}

//----------------------------------------------------------------------------
// SECTION WIDGETS
//----------------------------------------------------------------------------

/// Basic Information Section with name and dosage fields
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
        // Medication name field
        TextFormField(
            controller: nameController,
            decoration: AppTheme.defaultTextFieldDecoration.copyWith(
              labelText: 'Medication Name',
            ),
            validator: ValidationService.nameValidator),
        SharedWidgets.verticalSpace(),
        // Dosage field
        TextFormField(
          controller: dosageController,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Dosage',
            hintText: 'e.g., 50mg',
          ),
          validator: ValidationService.dosageValidator,
        ),
      ],
    );
  }
}

/// Medication Type Selection Section (Oral vs Injection)
class MedicationTypeSection extends StatelessWidget {
  final MedicationType medicationType;
  final ValueChanged<MedicationType> onTypeChanged;

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
        // Oral medication radio button
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
        // Injection medication radio button
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

/// Injection Details Section - Only shown for injection medications
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

  /// Helper method to build needle input sections
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
        // Needle type input
        TextFormField(
          initialValue: type,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Needle Type',
            hintText: typeHint,
          ),
          onChanged: onTypeChanged,
          validator: ValidationService.needleTypeValidator,
        ),
        SharedWidgets.verticalSpace(),
        Row(
          children: [
            // Count input
            Expanded(
              child: TextFormField(
                initialValue: count.toString(),
                decoration: AppTheme.defaultTextFieldDecoration.copyWith(
                  labelText: 'Count',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onCountChanged(int.tryParse(value) ?? 0),
                validator: ValidationService.numberValidator,
              ),
            ),
            SharedWidgets.verticalSpace(),
            // Refills input
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
                validator: ValidationService.numberValidator,
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

/// Timing Section for medication schedule
class TimingSection extends StatelessWidget {
  final int frequency;
  final List<TimeOfDay> times;
  final Set<String> selectedDays;
  final ValueChanged<int> onFrequencyChanged;
  final Function(int, TimeOfDay) onTimeChanged;
  final ValueChanged<Set<String>> onDaysChanged;
  final DateTime selectedStartDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final bool isEveryTwoWeeks;

  const TimingSection({
    super.key,
    required this.frequency,
    required this.times,
    required this.selectedDays,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onDaysChanged,
    required this.selectedStartDate,
    required this.onStartDateChanged,
    this.isEveryTwoWeeks = false,
  });

  /// Build the frequency selector (times per day)
  Widget _buildFrequencySelector() {
    return Row(
      children: [
        const Text('Times per day: '),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed:
              frequency > 1 ? () => onFrequencyChanged(frequency - 1) : null,
        ),
        Text('$frequency'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed:
              frequency < 10 ? () => onFrequencyChanged(frequency + 1) : null,
        ),
      ],
    );
  }

  /// Build the days of week selector
  Widget _buildDaySelector(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacing,
      children: [
        Text('Days: ', style: AppTextStyles.titleMedium),
        ...DateConstants.orderedDays.map((day) {
          final bool isSelected = selectedDays.contains(day);
          final bool canToggle =
              !isEveryTwoWeeks || selectedDays.length > 1 || !isSelected;

          return TextButton(
            onPressed: canToggle
                ? () {
                    final newDays = Set<String>.from(selectedDays);
                    if (isSelected) {
                      newDays.remove(day);
                    } else {
                      newDays.add(day);
                    }
                    onDaysChanged(newDays);
                  }
                : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              side: BorderSide(
                color: AppColors.outline,
              ),
              backgroundColor: isSelected ? AppColors.secondary : null,
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: AppTheme.bodyMedium.fontSize,
                color: isSelected ? AppColors.onPrimary : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Show date picker dialog and handle date selection
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2034),
    );
    if (picked != null && picked != selectedStartDate) {
      onStartDateChanged(picked);
    }
  }

  /// Build the start date selector
  Widget _buildStartDateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ListTile(
          title: Text(
            'Start Date: ${DateTimeFormatter.formatDateDDMMYY(selectedStartDate)}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectStartDate(context),
        ),
      ],
    );
  }

  /// Build time input for a specific time slot
  Widget _buildTimeInput(BuildContext context, int index) {
    final time = times[index];
    final isPM = time.hour >= 12;
    final hour12 =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Time ${index + 1}:',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          // Hour input
          SizedBox(
            width: 45,
            child: TextFormField(
              initialValue: hour12.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: AppTheme.defaultTextFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final newHour = int.parse(value);
                  if (newHour >= 1 && newHour <= 12) {
                    final hour24 = isPM
                        ? (newHour == 12 ? 12 : newHour + 12)
                        : (newHour == 12 ? 0 : newHour);
                    onTimeChanged(
                      index,
                      TimeOfDay(hour: hour24, minute: time.minute),
                    );
                  }
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(':', style: TextStyle(fontSize: 20)),
          ),
          // Minute input
          SizedBox(
            width: 45,
            child: TextFormField(
              initialValue: time.minute.toString().padLeft(2, '0'),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: AppTheme.defaultTextFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final newMinute = int.parse(value);
                  if (newMinute >= 0 && newMinute < 60) {
                    onTimeChanged(
                      index,
                      TimeOfDay(hour: time.hour, minute: newMinute),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // AM/PM toggle
          TextButton(
            onPressed: () {
              final currentHour = time.hour;
              final hour12 = currentHour > 12
                  ? currentHour - 12
                  : (currentHour == 0 ? 12 : currentHour);

              final newIsPM = !isPM;
              final newHour = newIsPM
                  ? (hour12 == 12 ? 12 : hour12 + 12)
                  : (hour12 == 12 ? 0 : hour12);

              onTimeChanged(
                index,
                TimeOfDay(hour: newHour, minute: time.minute),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: AppColors.outline),
            ),
            child: Text(
              isPM ? 'PM' : 'AM',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Timing',
      children: [
        _buildStartDateSelector(context),
        if (!isEveryTwoWeeks) _buildFrequencySelector(),
        SharedWidgets.verticalSpace(16),
        _buildDaySelector(context),
        SharedWidgets.verticalSpace(16),
        ...List.generate(
          frequency,
          (index) => _buildTimeInput(context, index),
        ),
      ],
    );
  }
}

/// Inventory Section for tracking medication quantities
class InventorySection extends StatelessWidget {
  final int currentQuantity;
  final int refillThreshold;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onThresholdChanged;

  const InventorySection({
    super.key,
    required this.currentQuantity,
    required this.refillThreshold,
    required this.onQuantityChanged,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Inventory',
      children: [
        _buildCounterRow(
          context,
          label: 'Current Quantity',
          value: currentQuantity,
          onChanged: onQuantityChanged,
          minValue: 0,
          showAddButton: true,
        ),
        SharedWidgets.verticalSpace(),
        _buildCounterRow(
          context,
          label: 'Refill Alert at',
          value: refillThreshold,
          onChanged: onThresholdChanged,
          minValue: 0,
          showAddButton: false,
        ),
      ],
    );
  }

  /// Build a row with counter and optional add button
  Widget _buildCounterRow(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int minValue,
    required bool showAddButton,
    int? maxValue,
  }) {
    final controller = TextEditingController(text: value.toString());
    final addController = TextEditingController(text: '30');

    return Row(
      children: [
        Text('$label: '),
        Flexible(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (String val) {
              final newValue = int.tryParse(val) ?? value;
              if (newValue >= minValue &&
                  (maxValue == null || newValue <= maxValue)) {
                onChanged(newValue);
              } else {
                controller.text = value.toString();
              }
            },
          ),
        ),
        if (showAddButton)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add More'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add More'),
                  content: TextField(
                    controller: addController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Amount to add',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => NavigationService.goBack(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        final amount = int.tryParse(addController.text) ?? 0;
                        final newValue = value + amount;
                        if (maxValue == null || newValue <= maxValue) {
                          onChanged(newValue);
                          controller.text = newValue.toString();
                        }
                        NavigationService.goBack(context);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Notes Section for additional information (optional)
class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SharedWidgets.basicCard(
      context: context,
      title: 'Notes',
      children: [
        TextFormField(
          controller: controller,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            hintText: 'Add any additional notes here',
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
