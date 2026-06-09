import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../theme/theme_manager.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';

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

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        setState(() {
          _isLoggingOut = false;
        });
        Navigator.of(context).pop();
      },
      child: PopScope(
        canPop: !_isLoggingOut,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(
                  'Settings & Privacy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
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
                        color: Colors.white,
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
                                  color: Colors.black,
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
          _ => '🏷️ Not Set',
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
              // Gender Identity
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: genderColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, color: genderColor, size: AppIconSize.sm),
                ),
                title: const Text(
                  'Gender Identity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
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

              // Hide Phone Number Toggle
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                secondary: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_disabled_outlined, color: Colors.teal, size: AppIconSize.sm),
                ),
                title: const Text(
                  'Hide Phone Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                subtitle: Text(
                  user.hidePhone ? 'Phone hidden from other players' : 'Phone visible to match organizers',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                value: user.hidePhone,
                activeThumbColor: Colors.teal,
                onChanged: (val) async {
                  try {
                    final authRepo = context.read<AuthRepository>();
                    final updatedUser = await authRepo.updateProfile(hidePhone: val);
                    if (context.mounted) {
                      context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),

              // Lavender Theme Toggle (only for female users)
              if (user.gender == 'female')
                AnimatedBuilder(
                  animation: themeManager,
                  builder: (context, _) {
                    final isLavender = themeManager.isWomenMode;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        gradient: isLavender
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFFF4D8D).withValues(alpha: 0.06),
                                  const Color(0xFF7B61FF).withValues(alpha: 0.04),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: isLavender
                            ? Border.all(color: const Color(0xFFFF4D8D).withValues(alpha: 0.2))
                            : null,
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                        secondary: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs + 2),
                          decoration: BoxDecoration(
                            gradient: isLavender
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF4D8D), Color(0xFF7B61FF)],
                                  )
                                : null,
                            color: isLavender ? null : Colors.grey.shade200,
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
                            const Text(
                              'Elegant Lavender Theme',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
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
                          
                          // Optimistic UI update
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
                      ),
                    );
                  },
                ),

              // General Settings
              _buildMenuTile(
                context,
                Icons.military_tech_outlined,
                'Dynamic Game Rules',
                'Read platform game guide',
                highlightColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sportigo platform game guide coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildMenuTile(
                context,
                Icons.history_toggle_off,
                'Platform Stats History',
                'Full tournament logs',
                highlightColor,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tournament logs coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 2),
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
          color: isDestructive ? Colors.red : Colors.black,
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
