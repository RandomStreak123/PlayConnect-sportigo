import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_spacing.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import 'profile_settings/widgets/settings_tile_list.dart';
import 'profile_settings/widgets/edit_profile_dialog.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final bool showEditProfileOnLoad;
  const ProfileSettingsScreen({super.key, this.showEditProfileOnLoad = false});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.showEditProfileOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = context.read<AuthBloc>().state.user;
        if (user != null) {
          showDialog(
            context: context,
            builder: (context) => EditProfileDialog(user: user),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: SettingsTileList(
                        onLoggingOutChanged: (val) {
                          setState(() {
                            _isLoggingOut = val;
                          });
                        },
                      ),
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
}
