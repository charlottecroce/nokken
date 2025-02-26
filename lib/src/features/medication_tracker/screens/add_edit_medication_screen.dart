//
//  add_edit_medication_screen.dart
//  Screen that handles both adding new medications and editing existing ones
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/services/navigation_service.dart';
import '../models/medication.dart';
import '../providers/medication_state.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_basic_info_section.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_medication_type_section.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_injection_details_section.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_timing_section.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_inventory_section.dart';
import 'package:nokken/src/features/medication_tracker/screens/widgets/edit_notes_section.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';

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

  List<TimeOfDay> _initializeTimes() {
    if (widget.medication != null) {
      return widget.medication!.timeOfDay
          .map((dt) => TimeOfDay.fromDateTime(dt))
          .toList();
    }
    return [TimeOfDay.now()];
  }

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

  // Handles saving/updating medication data
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
        // Get the updated medication from the state
        /*final updatedMedication = ref
            .read(medicationStateProvider)
            .medications
            .firstWhere((med) => med.id == medication.id);*/
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
            BasicInfoSection(
              nameController: _nameController,
              dosageController: _dosageController,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            MedicationTypeSection(
              medicationType: _medicationType,
              onTypeChanged: _handleTypeChange,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            if (_medicationType == MedicationType.injection)
              InjectionDetailsSection(
                injectionDetails: _injectionDetails!,
                onDetailsChanged: _updateInjectionDetails,
              ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            TimingSection(
              selectedStartDate: _startDate,
              onStartDateChanged: (date) => setState(() => _startDate = date),
              frequency: _frequency,
              times: _times,
              selectedDays: _selectedDays,
              onFrequencyChanged: _handleFrequencyChange,
              onTimeChanged: _handleTimeChange,
              onDaysChanged: _handleDaysChange,
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            InventorySection(
              currentQuantity: _currentQuantity,
              refillThreshold: _refillThreshold,
              onQuantityChanged: (value) =>
                  setState(() => _currentQuantity = value),
              onThresholdChanged: (value) =>
                  setState(() => _refillThreshold = value),
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),
            NotesSection(controller: _notesController),
          ],
        ),
      ),
    );
  }

// Helper method to update injection details
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
  }

  void _handleFrequencyChange(int newFrequency) {
    setState(() {
      _frequency = newFrequency;
      _times = _adjustTimesList(_times, newFrequency);
    });
  }

  List<TimeOfDay> _adjustTimesList(
      List<TimeOfDay> currentTimes, int newFrequency) {
    if (newFrequency > currentTimes.length) {
      return [
        ...currentTimes,
        ...List.generate(
          newFrequency - currentTimes.length,
          (_) => TimeOfDay.now(),
        )
      ];
    }
    return currentTimes.sublist(0, newFrequency);
  }

  void _handleDaysChange(Set<String> newDays) {
    setState(() {
      _selectedDays = newDays;
    });
  }

  void _handleTimeChange(int index, TimeOfDay newTime) {
    setState(() {
      _times[index] = newTime;
    });
  }
}
