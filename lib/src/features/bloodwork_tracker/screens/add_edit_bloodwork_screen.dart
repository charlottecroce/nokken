//
//  add_edit_bloodwork_screen.dart
//  Screen for adding or editing bloodwork records
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokken/src/features/bloodwork_tracker/models/bloodwork.dart';
import 'package:nokken/src/features/bloodwork_tracker/providers/bloodwork_state.dart';
import 'package:nokken/src/services/navigation_service.dart';
import 'package:nokken/src/shared/theme/app_icons.dart';
import 'package:nokken/src/shared/theme/app_theme.dart';
import 'package:nokken/src/shared/theme/shared_widgets.dart';
import 'package:nokken/src/shared/utils/date_time_formatter.dart';

class AddEditBloodworkScreen extends ConsumerStatefulWidget {
  final Bloodwork? bloodwork;

  const AddEditBloodworkScreen({
    super.key,
    this.bloodwork,
  });

  @override
  ConsumerState<AddEditBloodworkScreen> createState() =>
      _AddEditBloodworkScreenState();
}

class _AddEditBloodworkScreenState
    extends ConsumerState<AddEditBloodworkScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers that need disposal
  late final TextEditingController _locationController;
  late final TextEditingController _doctorController;
  late final TextEditingController _notesController;

  // List of hormone reading controllers
  final List<Map<String, dynamic>> _hormoneControllers = [];

  // State variables
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late AppointmentType _selectedAppointmentType;
  bool _isLoading = false;

  // Available hormone types for dropdown
  final List<String> _availableHormoneTypes = HormoneTypes.getHormoneTypes();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  /// Initialize all form fields with either existing bloodwork data or defaults
  void _initializeFields() {
    // Initialize date and time
    if (widget.bloodwork?.date != null) {
      _selectedDate = widget.bloodwork!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.bloodwork!.date);
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }

    // Initialize appointment type
    _selectedAppointmentType =
        widget.bloodwork?.appointmentType ?? AppointmentType.bloodwork;

    _locationController = TextEditingController(
      text: widget.bloodwork?.location ?? '',
    );

    _doctorController = TextEditingController(
      text: widget.bloodwork?.doctor ?? '',
    );

    _notesController = TextEditingController(
      text: widget.bloodwork?.notes ?? '',
    );

    // Initialize hormone controllers
    _initializeHormoneControllers();
  }

  /// Initialize hormone reading controllers from existing bloodwork or defaults
  void _initializeHormoneControllers() {
    if (widget.bloodwork != null) {
      // Try to use hormone readings
      if (widget.bloodwork!.hormoneReadings.isNotEmpty) {
        for (final reading in widget.bloodwork!.hormoneReadings) {
          _addHormoneField(
            name: reading.name,
            value: reading.value.toString(),
            unit: reading.unit,
          );
        }
      }
    }

    // If no hormone fields were added, add an empty one
    if (_hormoneControllers.isEmpty) {
      _addHormoneField();
    }
  }

  /// Add a new hormone field with optional preset values
  void _addHormoneField({String? name, String? value, String? unit}) {
    final nameController =
        TextEditingController(text: name ?? _availableHormoneTypes[0]);
    final valueController = TextEditingController(text: value ?? '');
    final unitController = TextEditingController(
      text: unit ?? HormoneTypes.getDefaultUnit(_availableHormoneTypes[0]),
    );

    setState(() {
      _hormoneControllers.add({
        'name': nameController,
        'value': valueController,
        'unit': unitController,
      });
    });

    // Automatically update unit when hormone type changes
    nameController.addListener(() {
      final hormoneName = nameController.text;
      final defaultUnit = HormoneTypes.getDefaultUnit(hormoneName);
      if (defaultUnit.isNotEmpty && unitController.text.isEmpty) {
        unitController.text = defaultUnit;
      }
    });
  }

  /// Remove a hormone field at the specified index
  void _removeHormoneField(int index) {
    if (_hormoneControllers.length <= 1) {
      // Don't remove the last field
      return;
    }

    setState(() {
      // Dispose controllers
      _hormoneControllers[index]['name'].dispose();
      _hormoneControllers[index]['value'].dispose();
      _hormoneControllers[index]['unit'].dispose();

      // Remove from list
      _hormoneControllers.removeAt(index);
    });
  }

  // Clean up controllers to prevent memory leaks
  @override
  void dispose() {
    _locationController.dispose();
    _doctorController.dispose();
    _notesController.dispose();

    // Dispose all hormone controllers
    for (final controllers in _hormoneControllers) {
      controllers['name'].dispose();
      controllers['value'].dispose();
      controllers['unit'].dispose();
    }

    super.dispose();
  }

  /// Show date picker dialog and handle date selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(
          days: 365 * 2)), // Allow scheduling up to 2 years in future
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Build time input field
  Widget _buildTimeInput(BuildContext context) {
    final isPM = _selectedTime.hour >= 12;
    final hour12 = _selectedTime.hour > 12
        ? _selectedTime.hour - 12
        : (_selectedTime.hour == 0 ? 12 : _selectedTime.hour);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Time:',
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
                    setState(() {
                      _selectedTime =
                          TimeOfDay(hour: hour24, minute: _selectedTime.minute);
                    });
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
              initialValue: _selectedTime.minute.toString().padLeft(2, '0'),
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
                    setState(() {
                      _selectedTime = TimeOfDay(
                          hour: _selectedTime.hour, minute: newMinute);
                    });
                  }
                }
              },
            ),
          ),
          SharedWidgets.horizontalSpace(12),
          // AM/PM toggle
          TextButton(
            onPressed: () {
              final currentHour = _selectedTime.hour;
              final hour12 = currentHour > 12
                  ? currentHour - 12
                  : (currentHour == 0 ? 12 : currentHour);

              final newIsPM = !isPM;
              final newHour = newIsPM
                  ? (hour12 == 12 ? 12 : hour12 + 12)
                  : (hour12 == 12 ? 0 : hour12);

              setState(() {
                _selectedTime =
                    TimeOfDay(hour: newHour, minute: _selectedTime.minute);
              });
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

  /// Check if selected date is in the future
  bool _isDateInFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selectedDate.isAfter(today);
  }

  /// Build appointment type radio buttons
  Widget _buildAppointmentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Type',
          style: AppTextStyles.titleSmall,
        ),
        SharedWidgets.verticalSpace(),
        // Bloodwork radio
        RadioListTile<AppointmentType>(
          title: const Text('Bloodwork'),
          value: AppointmentType.bloodwork,
          groupValue: _selectedAppointmentType,
          onChanged: (AppointmentType? value) {
            if (value != null) {
              setState(() {
                _selectedAppointmentType = value;
              });
            }
          },
        ),
        // Regular appointment radio
        RadioListTile<AppointmentType>(
          title: const Text('Doctor Visit'),
          value: AppointmentType.appointment,
          groupValue: _selectedAppointmentType,
          onChanged: (AppointmentType? value) {
            if (value != null) {
              setState(() {
                _selectedAppointmentType = value;
              });
            }
          },
        ),
        // Surgery radio
        RadioListTile<AppointmentType>(
          title: const Text('Surgery'),
          value: AppointmentType.surgery,
          groupValue: _selectedAppointmentType,
          onChanged: (AppointmentType? value) {
            if (value != null) {
              setState(() {
                _selectedAppointmentType = value;
              });
            }
          },
        ),
      ],
    );
  }

  /// Build location and doctor fields
  Widget _buildLocationDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location field
        TextFormField(
          controller: _locationController,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Location',
            hintText: 'Enter appointment location',
          ),
        ),
        SharedWidgets.verticalSpace(),

        // Doctor field
        TextFormField(
          controller: _doctorController,
          decoration: AppTheme.defaultTextFieldDecoration.copyWith(
            labelText: 'Healthcare Provider',
            hintText: 'Enter doctor or provider name',
          ),
        ),
      ],
    );
  }

  /// Build a single hormone input row
  Widget _buildHormoneInputRow(int index) {
    final nameController = _hormoneControllers[index]['name'];
    final valueController = _hormoneControllers[index]['value'];
    final unitController = _hormoneControllers[index]['unit'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hormone type dropdown
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              value: nameController.text,
              decoration: AppTheme.defaultTextFieldDecoration,
              style: AppTextStyles.bodyMedium,
              items: _availableHormoneTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  nameController.text = value;

                  // Update unit to match hormone type
                  final defaultUnit = HormoneTypes.getDefaultUnit(value);
                  if (defaultUnit.isNotEmpty) {
                    unitController.text = defaultUnit;
                  }
                }
              },
            ),
          ),

          SharedWidgets.horizontalSpace(2),

          // Hormone value input
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: valueController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: AppTheme.defaultTextFieldDecoration,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: AppTextStyles.bodySmall,
              validator: _isDateInFuture()
                  ? null
                  : (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Optional
                      }
                      final number = double.tryParse(value);
                      if (number == null) {
                        return 'Invalid number';
                      }
                      if (number < 0) {
                        return 'Cannot be negative';
                      }
                      return null;
                    },
            ),
          ),

          SharedWidgets.horizontalSpace(2),

          // Unit input (with default)
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: unitController,
              decoration: AppTheme.defaultTextFieldDecoration,
              readOnly: true,
              style: AppTextStyles.bodySmall,
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(AppIcons.getIcon('remove_circle')),
            onPressed: _hormoneControllers.length > 1
                ? () => _removeHormoneField(index)
                : null,
            color:
                _hormoneControllers.length > 1 ? AppColors.error : Colors.grey,
          ),
        ],
      ),
    );
  }

  /// Build hormone levels section for bloodwork
  Widget _buildHormoneLevelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Future date warning if applicable
        if (_isDateInFuture())
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: AppTheme.standardCardPadding,
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.getIcon('info'), color: AppColors.info),
                  SharedWidgets.horizontalSpace(),
                  Expanded(
                    child: Text(
                      'This is a future date. Hormone levels can be added after the lab date occurs.',
                      style: TextStyle(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // List of hormone inputs
        ...List.generate(
          _hormoneControllers.length,
          (index) => _buildHormoneInputRow(index),
        ),

        // Add button
        if (_hormoneControllers.length < 10 && !_isDateInFuture())
          Center(
            child: TextButton.icon(
              icon: Icon(AppIcons.getIcon('add')),
              label: const Text('Add Level'),
              onPressed: () => _addHormoneField(),
            ),
          ),
      ],
    );
  }

  /// Save or update bloodwork data
  Future<void> _saveBloodwork() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) return;

    // Only validate hormone values for past/present dates with bloodwork appointment type
    if (!_isDateInFuture() &&
        _selectedAppointmentType == AppointmentType.bloodwork) {
      // Get valid hormone readings
      final validReadings = _getValidHormoneReadings();

      if (validReadings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Please enter at least one hormone level for past or present bloodwork dates'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Create a DateTime that includes both date and time
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create bloodwork object from form data
      final bloodwork = Bloodwork(
        id: widget.bloodwork?.id, // null for new, existing id for updates
        date: dateTime,
        appointmentType: _selectedAppointmentType,
        hormoneReadings: _isDateInFuture()
            ? [] // No hormone readings for future dates
            : _getValidHormoneReadings(),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        doctor: _doctorController.text.trim().isNotEmpty
            ? _doctorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // If bloodwork is null, we're adding new
      // Otherwise, we're updating existing
      if (widget.bloodwork == null) {
        await ref.read(bloodworkStateProvider.notifier).addBloodwork(bloodwork);
      } else {
        await ref
            .read(bloodworkStateProvider.notifier)
            .updateBloodwork(bloodwork);
      }

      // Return to bloodwork list screen
      if (mounted) {
        NavigationService.goBack(context);
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

  /// Get valid hormone readings from the input fields
  List<HormoneReading> _getValidHormoneReadings() {
    final readings = <HormoneReading>[];

    for (final controller in _hormoneControllers) {
      final name = controller['name'].text;
      final valueText = controller['value'].text;
      final unit = controller['unit'].text;

      if (valueText.isNotEmpty) {
        final value = double.tryParse(valueText);
        if (value != null && value >= 0) {
          readings.add(HormoneReading(
            name: name,
            value: value,
            unit: unit.isNotEmpty ? unit : HormoneTypes.getDefaultUnit(name),
          ));
        }
      }
    }

    return readings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bloodwork == null ? 'Add Appointment' : 'Edit Appointment',
        ),
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
                  icon: Icon(AppIcons.getIcon('save')),
                  onPressed: _saveBloodwork,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppTheme.standardCardPadding,
          children: [
            // Date selection
            SharedWidgets.basicCard(
              context: context,
              title: 'Date and Time',
              children: [
                ListTile(
                  title: Text(
                    'Date: ${DateTimeFormatter.formatDateDDMMYY(_selectedDate)}',
                  ),
                  trailing: Icon(AppIcons.getIcon('calendar')),
                  onTap: () => _selectDate(context),
                ),
                // Add the time picker
                _buildTimeInput(context),
                _buildLocationDoctorFields(),
              ],
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Appointment type selection
            SharedWidgets.basicCard(
              context: context,
              title: 'Appointment Details',
              children: [
                _buildAppointmentTypeSelector(),
                SharedWidgets.verticalSpace(AppTheme.cardSpacing),
              ],
            ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Hormone levels (only shown for bloodwork type)
            if (_selectedAppointmentType == AppointmentType.bloodwork)
              SharedWidgets.basicCard(
                context: context,
                title: 'Hormone Levels',
                children: [
                  _buildHormoneLevelsSection(),
                ],
              ),
            SharedWidgets.verticalSpace(AppTheme.cardSpacing),

            // Notes section
            SharedWidgets.basicCard(
              context: context,
              title: 'Notes',
              children: [
                TextFormField(
                  controller: _notesController,
                  decoration: AppTheme.defaultTextFieldDecoration.copyWith(
                    hintText: 'Add any additional notes here',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
