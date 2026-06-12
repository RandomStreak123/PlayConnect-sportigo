import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../theme/theme_manager.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../data/models/user_model.dart';


class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    const highlightColor = AppColors.sportsGreen;

    return PopScope(
      canPop: !_isLoggingOut,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
              leading: _isLoggingOut ? const SizedBox.shrink() : const BackButton(),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: _buildSettingsList(context, highlightColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoggingOut)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLoadingIndicator(
                          color: AppColors.sportsGreen,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Signing out...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.none,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, Color highlightColor) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox.shrink();

        final themeManager = context.watch<ThemeManager>();
        final genderLabel = switch (user.gender) {
          'female' => '♀ Female',
          'male' => '♂ Male',
          'other' => '⚧ Other',
          _ => 'Not Set',
        };
        final genderColor = switch (user.gender) {
          'female' => const Color(0xFFFF4D8D),
          'male' => const Color(0xFF4A90D9),
          _ => Colors.grey.shade600,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edit Profile Menu Option
              _buildMenuTile(
                context,
                Icons.edit_outlined,
                'Edit Profile',
                'Update display name, bio, and settings',
                AppColors.warmOrange,
                () {
                  _showEditProfileModal(context, user);
                },
              ),

              // Gender Identity
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: genderColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: genderColor, size: AppIconSize.sm),
                ),
                title: Text(
                  'Gender Identity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                ),
                subtitle: Text(
                  genderLabel,
                  style: TextStyle(fontSize: 12, color: genderColor, fontWeight: FontWeight.w600),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: AppIconSize.sm),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gender can be updated during registration'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              if (user.gender == 'female') ...[
                AnimatedBuilder(
                  animation: themeManager,
                  builder: (context, _) {
                    final isLavender = themeManager.isWomenMode;
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      secondary: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: isLavender ? const Color(0xFFFF4D8D).withValues(alpha: 0.1) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: isLavender ? Colors.white : Colors.grey.shade600,
                          size: AppIconSize.sm,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            'Elegant Lavender Theme',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(width: AppSpacing.xxs + 2),
                          if (isLavender)
                            const Text('🌸', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      subtitle: Text(
                        isLavender
                            ? 'Soft pink & lavender experience active'
                            : 'Switch to elegant lavender palette',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLavender ? const Color(0xFFFF4D8D) : Colors.grey.shade600,
                        ),
                      ),
                      value: isLavender,
                      activeThumbColor: const Color(0xFFFF4D8D),
                      onChanged: (val) async {
                        final newPref = val
                            ? ThemePreference.elegantLavender
                            : ThemePreference.activeSteelBlue;
                        
                        themeManager.setThemePreference(newPref);
                        
                        try {
                          final authRepo = context.read<AuthRepository>();
                          final authBloc = context.read<AuthBloc>();
                          
                          final updatedUser = await authRepo.updateProfile(
                            themePreference: val ? 'elegantLavender' : 'activeSteelBlue',
                          );
                          
                          authBloc.add(AuthUserUpdated(updatedUser));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save theme preference to server'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],

              // Dynamic Game Rules
              _buildMenuTile(
                context,
                Icons.shield_outlined,
                'Dynamic Game Rules',
                'Read platform game guide',
                const Color(0xFF4A90D9),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sportigo platform game guide coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // Platform Stats History
              _buildMenuTile(
                context,
                Icons.bar_chart_outlined,
                'Platform Stats History',
                'Full tournament logs',
                Colors.teal,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tournament logs coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // Sign Out
              _buildMenuTile(
                context,
                Icons.logout_rounded,
                'Sign Out',
                'Exit application cleanly',
                Colors.redAccent,
                () {
                  _showSignOutConfirmation(context);
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    
    String? selectedSport = user.primarySport;
    String? selectedGender;
    if (user.gender != null) {
      final g = user.gender!.toLowerCase();
      if (g == 'male' || g == 'female' || g == 'other') {
        selectedGender = g;
      }
    }
    
    String? selectedSkillTier;
    if (user.skillTier != null) {
      const tiers = ['Beginner', 'Intermediate', 'Advanced', 'Expert', 'Professional', 'Elite'];
      for (final tier in tiers) {
        if (tier.toLowerCase() == user.skillTier!.trim().toLowerCase()) {
          selectedSkillTier = tier;
          break;
        }
      }
    }
    
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
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

              final List<Map<String, String>> sports = [
                {'name': 'Football', 'emoji': '⚽'},
                {'name': 'Cricket', 'emoji': '🏏'},
                {'name': 'Badminton', 'emoji': '🏸'},
                {'name': 'Basketball', 'emoji': '🏀'},
                {'name': 'Tennis', 'emoji': '🎾'},
                {'name': 'Padel', 'emoji': '🏓'},
              ];

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                    
                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display Name
                            Text('Display Name', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                border: borderStyle,
                                enabledBorder: borderStyle,
                                focusedBorder: focusedBorderStyle,
                                filled: true,
                                fillColor: textFieldFillColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            
                            // Email Address
                            Text('Email Address (for Google Login Link)', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: emailController,
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                border: borderStyle,
                                enabledBorder: borderStyle,
                                focusedBorder: focusedBorderStyle,
                                filled: true,
                                fillColor: textFieldFillColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            
                            // Bio
                            Text('Bio (Tell others about yourself)', style: labelStyle),
                            const SizedBox(height: 8),
                            TextField(
                              controller: bioController,
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
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 20),
                            
                            // Primary Sport
                            Text('Primary Sport', style: labelStyle),
                            const SizedBox(height: 12),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.6,
                              children: sports.map((sport) {
                                final name = sport['name']!;
                                final emoji = sport['emoji']!;
                                final isSelected = selectedSport == name;
                                final pillBgColor = isSelected
                                    ? const Color(0xFF10B981)
                                    : textFieldFillColor;
                                final pillBorderColor = isSelected
                                    ? const Color(0xFF10B981)
                                    : textFieldBorderColor;
                                final pillTextColor = isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF475569));
                                    
                                return GestureDetector(
                                  onTap: isSaving ? null : () {
                                    setModalState(() {
                                      selectedSport = name;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: pillBgColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: pillBorderColor, width: 1),
                                    ),
                                    child: Row(
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
                            ),
                            const SizedBox(height: 20),
                            
                            // Gender & skillTier
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Gender', style: labelStyle),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedGender,
                                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                        decoration: InputDecoration(
                                          border: borderStyle,
                                          enabledBorder: borderStyle,
                                          focusedBorder: focusedBorderStyle,
                                          filled: true,
                                          fillColor: textFieldFillColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                        dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                                        items: const [
                                          DropdownMenuItem(value: 'male', child: Text('Male')),
                                          DropdownMenuItem(value: 'female', child: Text('Female')),
                                          DropdownMenuItem(value: 'other', child: Text('Other')),
                                        ],
                                        onChanged: isSaving ? null : (val) {
                                          setModalState(() {
                                            selectedGender = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('skillTier', style: labelStyle),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedSkillTier,
                                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                        decoration: InputDecoration(
                                          border: borderStyle,
                                          enabledBorder: borderStyle,
                                          focusedBorder: focusedBorderStyle,
                                          filled: true,
                                          fillColor: textFieldFillColor,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                                        dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                                        items: [
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
                                        onChanged: isSaving ? null : (val) {
                                          setModalState(() {
                                            selectedSkillTier = val;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Save / Cancel Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving ? null : () => Navigator.pop(context),
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
                                    onPressed: isSaving
                                        ? null
                                        : () async {
                                            final name = nameController.text.trim();
                                            if (name.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Display Name cannot be empty'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                              return;
                                            }

                                            setModalState(() {
                                              isSaving = true;
                                            });

                                            try {
                                              final authRepo = context.read<AuthRepository>();
                                              final updatedUser = await authRepo.updateProfile(
                                                name: name,
                                                email: emailController.text.trim().isEmpty ? '' : emailController.text.trim(),
                                                bio: bioController.text.trim(),
                                                primarySport: selectedSport,
                                                gender: selectedGender,
                                                skillTier: selectedSkillTier,
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
                                              setModalState(() {
                                                isSaving = false;
                                              });
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update profile: $e'),
                                                    backgroundColor: Theme.of(context).colorScheme.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
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
                                    child: isSaving
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
              );
            },
          ),
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign Out?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to log in again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isLoggingOut = true;
                        });
                        context.read<AuthBloc>().add(const AuthLogoutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: AppIconSize.sm),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
        size: AppIconSize.sm,
      ),
      onTap: onTap,
    );
  }
}
