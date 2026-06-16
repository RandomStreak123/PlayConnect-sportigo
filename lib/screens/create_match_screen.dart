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

  final List<String> _sports = ['Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket'];
  final List<String> _skills = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

  static const double _fieldHeight = 52;

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

  void _submitForm() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
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
              _buildLabel('Sport Type'),
              _buildDropdown(
                value: _selectedSport,
                items: _sports,
                onChanged: (val) => setState(() => _selectedSport = val!),
              ),
              const SizedBox(height: 20),

              // Title Input
              _buildLabel('Match Title'),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g., Friday Evening 5v5',
                validator: (val) => val!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),

              // Date & Time Picker
              _buildLabel('Date & Time'),
              GestureDetector(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: AppIconSize.sm),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Input
              _buildLabel('Location'),
              _buildTextField(
                controller: _locationController,
                hint: 'e.g., Central Park Court 2',
                icon: Icons.location_on_outlined,
                validator: (val) => val!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final useVertical = constraints.maxWidth < 320;
                  final children = [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Available Slots'),
                        _buildTextField(
                          controller: _slotsController,
                          hint: 'e.g., 10',
                          keyboardType: TextInputType.number,
                          fixedHeight: false,
                          validator: (val) {
                            if (val!.isEmpty) return 'Required';
                            if (int.tryParse(val) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Skill Level'),
                        _buildDropdown(
                          value: _selectedSkill,
                          items: _skills,
                          onChanged: (val) => setState(() => _selectedSkill = val!),
                        ),
                      ],
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: _womenOnly
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF4D8D).withValues(alpha: 0.08),
                                  const Color(0xFF7B61FF).withValues(alpha: 0.05),
                                ],
                              )
                            : null,
                        color: _womenOnly ? null : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _womenOnly
                              ? const Color(0xFFFF4D8D).withValues(alpha: 0.4)
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                        title: Row(
                          children: [
                            Text(
                              '🌸',
                              style: TextStyle(fontSize: _womenOnly ? 20 : 16),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Text(
                              'Women-Only Match',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          _womenOnly
                              ? 'Only female players can join this match'
                              : 'Enable to restrict to women players',
                          style: TextStyle(
                            fontSize: 12,
                            color: _womenOnly
                                ? const Color(0xFFFF4D8D)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: _womenOnly,
                        activeThumbColor: const Color(0xFFFF4D8D),
                        onChanged: (val) => setState(() => _womenOnly = val),
                      ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xxs),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputBorder _fieldBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(
        color: focused
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        width: focused ? 2 : 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool fixedHeight = false,
    String? Function(String?)? validator,
  }) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: Theme.of(context).colorScheme.outline)
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: icon != null ? 0 : AppSpacing.md,
          vertical: fixedHeight ? AppSpacing.md : AppSpacing.md,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(focused: true),
      ),
    );

    if (!fixedHeight) return field;

    return SizedBox(height: _fieldHeight, child: field);
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: Theme.of(context).textTheme.bodyLarge,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
