import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../theme/theme_manager.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icon_size.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../game_rules_screen.dart';
import '../../policy_guidelines_screen.dart';
import 'edit_profile_dialog.dart';

class SettingsTileList extends StatelessWidget {
  final Function(bool) onLoggingOutChanged;

  const SettingsTileList({
    super.key,
    required this.onLoggingOutChanged,
  });

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
                        onLoggingOutChanged(true);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) return const SizedBox.shrink();

        final themeManager = context.watch<ThemeManager>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuTile(
                context,
                Icons.edit_outlined,
                'Edit Profile',
                'Update display name, bio, and settings',
                AppColors.warmOrange,
                () {
                  showDialog(
                    context: context,
                    builder: (context) => EditProfileDialog(user: user),
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
                      title: Text(
                        'Elegant Lavender Theme',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
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
                          final authRepo = getIt<AuthRepository>();
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
              _buildMenuTile(
                context,
                Icons.shield_outlined,
                'Dynamic Game Rules',
                'Read platform game guide',
                const Color(0xFF4A90D9),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameRulesScreen(),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                context,
                Icons.description_outlined,
                'Policy & Guidelines',
                'Read platform terms and guidelines',
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PolicyGuidelinesScreen(),
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
}
