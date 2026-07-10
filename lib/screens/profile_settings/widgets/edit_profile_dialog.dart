import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;

  const EditProfileDialog({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  
  String? _selectedSport;
  String? _selectedGender;
  String? _selectedSkillTier;
  bool _isSaving = false;
  String? _emailError;

  final List<Map<String, String>> _sports = const [
    {'name': 'Football', 'emoji': '⚽'},
    {'name': 'Cricket', 'emoji': '🏏'},
    {'name': 'Badminton', 'emoji': '🏸'},
    {'name': 'Basketball', 'emoji': '🏀'},
    {'name': 'Tennis', 'emoji': '🎾'},
    {'name': 'Padel', 'emoji': '🏓'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _emailController.addListener(() {
      if (_emailError != null) {
        setState(() {
          _emailError = null;
        });
      }
    });
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _selectedSport = widget.user.primarySport;
    
    if (widget.user.gender != null) {
      final g = widget.user.gender!.toLowerCase();
      if (g == 'male' || g == 'female' || g == 'other') {
        _selectedGender = g;
      }
    }

    if (widget.user.skillTier != null) {
      const tiers = ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Professional', 'Elite'];
      for (final tier in tiers) {
        if (tier.toLowerCase() == widget.user.skillTier!.trim().toLowerCase()) {
          _selectedSkillTier = tier;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = const TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
    
    final textFieldFillColor = isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white;
    final textFieldBorderColor = isDark ? Colors.grey.shade700 : const Color(0xFFE2E8F0);
    
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: textFieldBorderColor),
    );
    
    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
    );

    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 12, top: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F1E4A),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display Name', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        border: borderStyle,
                        enabledBorder: borderStyle,
                        focusedBorder: focusedBorderStyle,
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 16),
                    Text('Email Address', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        border: _emailError != null ? errorBorderStyle : borderStyle,
                        enabledBorder: _emailError != null ? errorBorderStyle : borderStyle,
                        focusedBorder: _emailError != null ? errorBorderStyle : focusedBorderStyle,
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isSaving,
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _emailError!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Bio (Tell others about yourself)', style: labelStyle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        border: borderStyle,
                        enabledBorder: borderStyle,
                        focusedBorder: focusedBorderStyle,
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 4,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 20),
                    Text('Primary Sport', style: labelStyle),
                    const SizedBox(height: 12),
                    _SportPillSelector(
                      sports: _sports,
                      selectedSport: _selectedSport,
                      isSaving: _isSaving,
                      textFieldFillColor: textFieldFillColor,
                      textFieldBorderColor: textFieldBorderColor,
                      isDark: isDark,
                      onSportSelected: (sport) {
                        setState(() {
                          _selectedSport = sport;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileDropdownSelector(
                            label: 'Gender',
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedGender = val;
                                    });
                                  },
                            isDark: isDark,
                            fillColor: textFieldFillColor,
                            borderStyle: borderStyle,
                            focusedBorderStyle: focusedBorderStyle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ProfileDropdownSelector(
                            label: 'skillTier',
                            value: _selectedSkillTier,
                            items: const [
                              'Beginner',
                              'Intermediate',
                              'Advanced',
                              'Expert',
                              'Professional',
                              'Elite'
                            ].map((tier) {
                              return DropdownMenuItem(
                                value: tier,
                                child: Text(tier),
                              );
                            }).toList(),
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedSkillTier = val;
                                    });
                                  },
                            isDark: isDark,
                            fillColor: textFieldFillColor,
                            borderStyle: borderStyle,
                            focusedBorderStyle: focusedBorderStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: textFieldBorderColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    final name = _nameController.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Display Name cannot be empty'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _isSaving = true;
                                    });

                                    try {
                                      final authRepo = getIt<AuthRepository>();
                                      final updatedUser = await authRepo.updateProfile(
                                        name: name,
                                        email: _emailController.text.trim().isEmpty ? '' : _emailController.text.trim(),
                                        bio: _bioController.text.trim(),
                                        primarySport: _selectedSport,
                                        gender: _selectedGender,
                                        skillTier: _selectedSkillTier,
                                      );

                                      if (context.mounted) {
                                        context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile updated successfully!'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() {
                                        _isSaving = false;
                                      });
                                      if (context.mounted) {
                                        final errorMsg = e.toString().replaceAll('Exception: ', '');
                                        if (errorMsg.toLowerCase().contains('email')) {
                                          setState(() {
                                            _emailError = errorMsg;
                                          });
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Update Failed'),
                                              content: Text(errorMsg),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Sport Pill Selector Widget ────────────────────────────────────────
class _SportPillSelector extends StatelessWidget {
  final List<Map<String, String>> sports;
  final String? selectedSport;
  final bool isSaving;
  final Color textFieldFillColor;
  final Color textFieldBorderColor;
  final bool isDark;
  final ValueChanged<String?> onSportSelected;

  const _SportPillSelector({
    required this.sports,
    required this.selectedSport,
    required this.isSaving,
    required this.textFieldFillColor,
    required this.textFieldBorderColor,
    required this.isDark,
    required this.onSportSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sports.map((sport) {
        final name = sport['name']!;
        final emoji = sport['emoji']!;
        final isSelected = selectedSport == name;
        final pillBgColor = isSelected ? const Color(0xFF10B981) : textFieldFillColor;
        final pillBorderColor = isSelected ? const Color(0xFF10B981) : textFieldBorderColor;
        final pillTextColor = isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF475569));

        return GestureDetector(
          onTap: isSaving ? null : () => onSportSelected(name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: pillBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pillBorderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: pillTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Custom Dropdown Selector Widget ──────────────────────────────────────────
class _ProfileDropdownSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isDark;
  final Color fillColor;
  final InputBorder borderStyle;
  final InputBorder focusedBorderStyle;

  const _ProfileDropdownSelector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.fillColor,
    required this.borderStyle,
    required this.focusedBorderStyle,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(
      color: Color(0xFF64748B),
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
          decoration: InputDecoration(
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: focusedBorderStyle,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
