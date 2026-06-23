import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/avatar_image_helper.dart';

class ProfileCard extends StatefulWidget {
  final bool isCurrentUser;
  final String? playerName;
  final String? profilePicture;
  final int? userId;
  final Map<String, dynamic>? publicProfileData;
  final String selectedTheme;
  final Color sportColor;
  final Function(UserModel)? onPhotoUploaded;

  const ProfileCard({
    super.key,
    required this.isCurrentUser,
    this.playerName,
    this.profilePicture,
    this.userId,
    this.publicProfileData,
    required this.selectedTheme,
    required this.sportColor,
    this.onPhotoUploaded,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isUploading = false;
  bool _isEditButtonHovered = false;

  List<Color> _getAvatarBorderColors(int level, Color sportColor) {
    if (level >= 25) {
      return [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA500), // Orange/Amber
        const Color(0xFFFFD700),
      ];
    } else if (level >= 10) {
      return [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFF8DC), // Cornsilk
        const Color(0xFFFFD700),
      ];
    } else if (level >= 5) {
      return [
        const Color(0xFFC0C0C0), // Silver
        const Color(0xFFFFFFFF), // White
        const Color(0xFFC0C0C0),
      ];
    } else if (level >= 2) {
      return [
        const Color(0xFFCD7F32), // Bronze
        const Color(0xFFE5A65D), // Light Bronze
        const Color(0xFFCD7F32),
      ];
    } else {
      return [
        sportColor,
        sportColor.withValues(alpha: 0.4),
        AppColors.electricCyan,
        sportColor,
      ];
    }
  }

  BoxShadow _getAvatarBorderShadow(int level, Color sportColor) {
    if (level >= 25) {
      return BoxShadow(
        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
        blurRadius: 18,
        spreadRadius: 3,
      );
    } else if (level >= 10) {
      return BoxShadow(
        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        blurRadius: 15,
        spreadRadius: 2,
      );
    } else if (level >= 5) {
      return BoxShadow(
        color: const Color(0xFFC0C0C0).withValues(alpha: 0.3),
        blurRadius: 12,
        spreadRadius: 2,
      );
    } else if (level >= 2) {
      return BoxShadow(
        color: const Color(0xFFCD7F32).withValues(alpha: 0.25),
        blurRadius: 10,
        spreadRadius: 1,
      );
    } else {
      return BoxShadow(
        color: sportColor.withValues(alpha: 0.3),
        blurRadius: 15,
        spreadRadius: 2,
      );
    }
  }

  String _getLevelBadge(int level) {
    if (level >= 25) return '🏆';
    if (level >= 10) return '🥇';
    if (level >= 5) return '🎖️';
    if (level >= 2) return '💫';
    return '👟';
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final authRepository = getIt<AuthRepository>();
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primaryContainer),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primaryContainer),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final updatedUser = await authRepository.uploadProfilePhoto(pickedFile.path);

      if (!mounted) return;

      authBloc.add(AuthUserUpdated(updatedUser));
      if (widget.onPhotoUploaded != null) {
        widget.onPhotoUploaded!(updatedUser);
      }
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: AppColors.sportsGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to upload profile photo: $e'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userForTheme = context.read<AuthBloc>().state.user;
    final level = widget.publicProfileData?['stats']?['level'] as int? ??
        (widget.isCurrentUser ? (userForTheme?.stats?.level ?? 1) : 1);

    final themeGlowColor = widget.selectedTheme == 'Default'
        ? widget.sportColor
        : (widget.selectedTheme == 'Lavender Dusk'
            ? const Color(0xFF8A2BE2)
            : const Color(0xFFD4AF37));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeGlowColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: themeGlowColor.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: BlocSelector<AuthBloc, AuthState, String?>(
                    selector: (state) => state.user?.profilePhotoUrl,
                    builder: (context, profilePhotoUrl) {
                      final photoUrl = widget.publicProfileData?['avatar'] as String? ?? 
                          widget.publicProfileData?['profile_picture'] as String? ?? 
                          widget.publicProfileData?['profile_photo'] as String? ?? 
                          (widget.isCurrentUser ? profilePhotoUrl : widget.profilePicture);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 146,
                            height: 146,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: _getAvatarBorderColors(level, widget.sportColor),
                              ),
                              boxShadow: [
                                _getAvatarBorderShadow(level, widget.sportColor),
                              ],
                            ),
                          ),
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          GestureDetector(
                            onTap: (widget.isCurrentUser && !_isUploading) ? () => _pickAndUploadImage(context) : null,
                            child: Hero(
                              tag: 'profile_avatar_hero',
                              child: Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.surfaceDim,
                                ),
                                child: (photoUrl != null && AvatarImageHelper.resolveUrl(photoUrl) != null)
                                    ? ClipOval(
                                        child: Image.network(
                                          AvatarImageHelper.resolveUrl(photoUrl)!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.person, size: 60, color: Colors.white70);
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: AppLoadingIndicator());
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 60, color: Colors.white70),
                              ),
                            ),
                          ),
                          if (widget.isCurrentUser) Positioned(
                            bottom: 0,
                            right: 4,
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _isEditButtonHovered = true),
                              onTapUp: (_) => setState(() => _isEditButtonHovered = false),
                              onTapCancel: () => setState(() => _isEditButtonHovered = false),
                              onTap: _isUploading ? null : () => _pickAndUploadImage(context),
                              child: AnimatedScale(
                                scale: _isEditButtonHovered ? 0.85 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.sportColor, AppColors.electricCyan],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.sportColor.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _isUploading
                                      ? const AppLoadingIndicator(color: Colors.white)
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                BlocSelector<AuthBloc, AuthState, String?>(
                  selector: (state) => state.user?.name,
                  builder: (context, name) {
                    final userName = widget.publicProfileData?['name'] as String? ??
                        (widget.isCurrentUser ? (name ?? 'Sportigo Champ') : (widget.playerName ?? 'Player'));
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLevelBadge(level),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.electricCyan,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
