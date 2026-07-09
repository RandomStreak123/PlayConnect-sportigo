import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../widgets/app_loading_indicator.dart';
import '../data/models/match_model.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';
import 'location_picker_screen.dart';
import 'create_match/widgets/create_match_form_field.dart';
import 'create_match/widgets/create_match_dropdown.dart';
import 'create_match/widgets/women_only_toggle.dart';
import 'create_match/widgets/create_match_date_time_picker.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _slotsController = TextEditingController();
  
  String _selectedSport = 'Football';
  String _selectedSkill = 'Intermediate';
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  bool _womenOnly = false;
  bool _isSubmitting = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  final List<String> _sports = ['Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket'];
  final List<String> _skills = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialAddress: _locationController.text,
        ),
      ),
    );

    if (result != null && result.address.isNotEmpty) {
      if (!mounted) return;
      double lat = result.latitude;
      double lon = result.longitude;

      // Scan existing matches in the Bloc state to see if we can reuse precise coordinates
      final matches = context.read<MatchBloc>().state.matches;
      for (final m in matches) {
        if (m.location == result.address && m.latitude != null && m.latitude != 0.0) {
          lat = m.latitude!;
          lon = m.longitude!;
          debugPrint('REUSE_COORDS: Inherited precise coordinates ($lat, $lon) from existing match at: ${m.location}');
          break;
        }
      }

      setState(() {
        _locationController.text = result.address;
        _selectedLatitude = lat;
        _selectedLongitude = lon;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      debugPrint('Selected coordinates: $_selectedLatitude, $_selectedLongitude');
      final openSlots = int.parse(_slotsController.text);
      final match = MatchModel(
        id: '',
        sportType: _selectedSport,
        title: _titleController.text,
        dateTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDate),
        location: _locationController.text,
        availableSlots: openSlots,
        maxSlots: openSlots + 1,
        joinedCount: 0,
        skillLevel: _selectedSkill,
        participants: const [],
        distance: 0.0,
        womenOnly: _womenOnly,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      setState(() => _isSubmitting = true);
      context.read<MatchBloc>().add(MatchCreated(match));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        if (!_isSubmitting || state.message == null) return;
        if (state.isActionSuccess) {
          Navigator.pop(context);
        } else {
          setState(() => _isSubmitting = false);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Create New Match'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Sport Type Dropdown
                CreateMatchDropdown(
                  label: 'Sport Type',
                  value: _selectedSport,
                  items: _sports,
                  onChanged: (val) => setState(() => _selectedSport = val!),
                ),
                const SizedBox(height: 20),

                // Title Input
                CreateMatchFormField(
                  label: 'Match Title',
                  controller: _titleController,
                  hint: 'e.g., Friday Evening 5v5',
                  validator: (val) => val!.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                // Date & Time Picker
                CreateMatchDateTimePicker(
                  selectedDate: _selectedDate,
                  onTap: _selectDateTime,
                ),
                const SizedBox(height: 20),

                // Location Input
                CreateMatchFormField(
                  label: 'Location',
                  controller: _locationController,
                  hint: 'Choose location from map',
                  icon: Icons.location_on,
                  readOnly: true,
                  onTap: _pickLocation,
                  validator: (val) => val!.isEmpty ? 'Please enter a location' : null,
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final useVertical = constraints.maxWidth < 320;
                    final children = [
                      CreateMatchFormField(
                        label: 'Available Slots',
                        controller: _slotsController,
                        hint: 'e.g., 10',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val!.isEmpty) return 'Required';
                          if (int.tryParse(val) == null) return 'Invalid';
                          return null;
                        },
                      ),
                      CreateMatchDropdown(
                        label: 'Skill Level',
                        value: _selectedSkill,
                        items: _skills,
                        onChanged: (val) => setState(() => _selectedSkill = val!),
                      ),
                    ];

                    if (useVertical) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          children[0],
                          const SizedBox(height: 20),
                          children[1],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
                
                // Women-Only Match Toggle (only for female users)
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState.user?.gender != 'female') {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: WomenOnlyToggle(
                        value: _womenOnly,
                        onChanged: (val) => setState(() => _womenOnly = val),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const AppLoadingIndicator(color: Colors.white)
                        : const Text(
                            'Create Match',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
