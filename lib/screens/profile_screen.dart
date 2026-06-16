import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../core/utils/avatar_image_helper.dart';
import 'profile_settings_screen.dart';
import '../logic/blocs/matches/match_bloc.dart';
import '../data/models/match_model.dart';
import '../data/models/activity_model.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  final bool isCurrentUser;
  final String? playerName;
  final String? profilePicture;
  final int? userId;

  const ProfileScreen({
    super.key,
    this.isCurrentUser = true,
    this.playerName,
    this.profilePicture,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  String _selectedSport = 'Football';
  int _activeActivityTab = 0; // 0: Activity, 1: Achievements, 2: Streaks
  late AnimationController _animationController;
  late ScrollController _scrollController;
  
  // Implicit animation trigger states
  bool _isEditButtonHovered = false;

  // Dynamic Profile screen customization features
  bool _showAllActivities = false;
  String _selectedTheme = 'Default';
  int _selectedWeekOffset = 0;

  final List<Map<String, dynamic>> _sportsList = [
    {'name': 'Football', 'icon': '⚽'},
    {'name': 'Cricket', 'icon': '🏏'},
    {'name': 'Badminton', 'icon': '🏸'},
    {'name': 'Basketball', 'icon': '🏀'},
    {'name': 'Tennis', 'icon': '🎾'},
    {'name': 'Padel', 'icon': '🏓'},
  ];

  Map<String, dynamic>? _publicProfileData;
  String? _publicProfileError;

  final Map<String, List<Color>> _premiumGradients = {
    'Default': [],
    'Lavender Dusk': [
      const Color(0xFF2E0854),
      const Color(0xFF8A2BE2),
      const Color(0xFFE6E6FA),
    ],
    'Gold Rush': [
      const Color(0xFF3A2D00),
      const Color(0xFF8A7300),
      const Color(0xFFD4AF37),
    ],
    'Golden Legend': [
      const Color(0xFF8B6C05),
      const Color(0xFFD4AF37),
      const Color(0xFFFFDF73),
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _scrollController = ScrollController();
    if (widget.isCurrentUser) {
      _loadSelectedTheme();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthBloc>().state.user?.id;
      if (widget.isCurrentUser) {
        if (currentUserId != null) {
          _loadPublicProfileWithId(currentUserId);
        }
        context.read<MatchBloc>().add(const MyMatchesFetched());
      } else {
        if (widget.userId != null) {
          _loadPublicProfileWithId(widget.userId!);
        }
      }
    });
  }

  Future<void> _loadSelectedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('profile_theme_key') ?? 'Default';
      if (mounted) {
        setState(() {
          _selectedTheme = savedTheme;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSelectedTheme(String themeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_theme_key', themeName);
      if (mounted) {
        setState(() {
          _selectedTheme = themeName;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPublicProfileWithId(int userId, {bool isRefresh = false}) async {
    final shouldShowLoader = !isRefresh && _publicProfileData == null && !widget.isCurrentUser;
    if (shouldShowLoader) {
      setState(() {
        _publicProfileError = null;
      });
    }
    try {
      final authRepository = context.read<AuthRepository>();
      final data = await authRepository.getPublicProfile(userId);
      if (mounted) {
        final level = data['stats']?['level'] as int? ?? 1;
        String theme = 'Default';
        if (level >= 25) {
          theme = 'Golden Legend';
        } else if (level >= 10) {
          theme = 'Gold Rush';
        } else if (level >= 5) {
          theme = 'Lavender Dusk';
        }
        setState(() {
          _publicProfileData = data;
          if (widget.isCurrentUser) {
            _loadSelectedTheme().then((_) {
              if (_selectedTheme == 'Default' || _selectedTheme.isEmpty) {
                setState(() {
                  _selectedTheme = theme;
                });
              }
            });
          } else {
            _selectedTheme = theme;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (shouldShowLoader) {
            _publicProfileError = e.toString().replaceAll('Exception: ', '');
          }
        });
      }
    }
  }

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

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getSportColor(BuildContext context, String sport) {
    switch (sport) {
      case 'Football':
        return AppColors.sportsGreen;
      case 'Cricket':
        return Colors.blue.shade600;
      case 'Basketball':
        return AppColors.warmOrange;
      case 'Tennis':
        return Colors.lime.shade700;
      case 'Padel':
        return Colors.teal;
      case 'Badminton':
        return Colors.purple.shade600;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final authRepository = context.read<AuthRepository>();
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

    if (_publicProfileError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_publicProfileError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final uid = widget.isCurrentUser
                      ? context.read<AuthBloc>().state.user?.id
                      : widget.userId;
                  if (uid != null) {
                    _loadPublicProfileWithId(uid);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final sportColor = _getSportColor(context, _selectedSport);
    
    final userForTheme = context.read<AuthBloc>().state.user;
    final levelForTheme = _publicProfileData?['stats']?['level'] as int? ??
        (widget.isCurrentUser ? (userForTheme?.stats?.level ?? 1) : 1);

    // Sanitize selected theme based on level requirements
    String activeTheme = _selectedTheme;
    if (widget.isCurrentUser) {
      if (activeTheme == 'Golden Legend' && levelForTheme < 25) {
        activeTheme = 'Default';
      } else if (activeTheme == 'Gold Rush' && levelForTheme < 10) {
        activeTheme = 'Default';
      } else if (activeTheme == 'Lavender Dusk' && levelForTheme < 5) {
        activeTheme = 'Default';
      }
    } else {
      if (levelForTheme >= 25) {
        activeTheme = 'Golden Legend';
      } else if (levelForTheme >= 10) {
        activeTheme = 'Gold Rush';
      } else if (levelForTheme >= 5) {
        activeTheme = 'Lavender Dusk';
      } else {
        activeTheme = 'Default';
      }
    }

    final premiumColors = _premiumGradients[activeTheme]!;
    final gradientColors = activeTheme == 'Default'
        ? [
            sportColor.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            Theme.of(context).colorScheme.surface,
          ]
        : [
            premiumColors[0].withValues(alpha: 0.2),
            premiumColors[1].withValues(alpha: 0.75),
            Theme.of(context).colorScheme.surface,
          ];

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background based on dynamic sport type colors
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Custom ambient animation for Golden Legend theme
          if (activeTheme == 'Golden Legend')
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final pulse = math.sin(_animationController.value * 2 * math.pi).abs();
                return Positioned.fill(
                  child: Opacity(
                    opacity: 0.03 + 0.04 * pulse,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0xFFD4AF37), Colors.transparent],
                          center: Alignment.topCenter,
                          radius: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final currentUserId = context.read<AuthBloc>().state.user?.id;
                final targetUserId = widget.isCurrentUser ? currentUserId : widget.userId;
                final matchBloc = context.read<MatchBloc>();
                if (targetUserId != null) {
                  await _loadPublicProfileWithId(targetUserId, isRefresh: true);
                }
                if (widget.isCurrentUser) {
                  matchBloc.add(const MyMatchesFetched());
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // App Bar / Title Header
                        _buildCustomAppBar(context),
                        
                        // Large Premium Profile Card with neon details
                        _buildLargeProfileCard(context, sportColor),
                        
                        // Complete Identity & Level Progression System
                        _buildLevelSection(context, sportColor),

                        // Custom Theme Selection Chips (unlocked at Level 5+)
                        _buildThemeSelector(context, levelForTheme, sportColor),
                        
                        // Premium Stat/Achievement Grid
                        _buildStatGrid(context, sportColor),
                        
                        // Interactive Sport Chips Section
                        _buildSportsSection(context, sportColor),
                        
                        // Responsive Segmented Activity/Streaks Section
                        _buildActivitySection(context, sportColor),
                        
                        const SizedBox(height: 100), // Padding for elegant floating bottom navigation
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCurrentUser) const BackButton(),
          Expanded(
            child: Text(
              'Player Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: widget.isCurrentUser ? TextAlign.start : TextAlign.center,
            ),
          ),
          if (widget.isCurrentUser)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
            )
          else
            const SizedBox(width: 48), // Balance for BackButton
        ],
      ),
    );
  }

  Widget _buildLargeProfileCard(BuildContext context, Color sportColor) {
    final userForTheme = context.read<AuthBloc>().state.user;
    final level = _publicProfileData?['stats']?['level'] as int? ??
        (widget.isCurrentUser ? (userForTheme?.stats?.level ?? 1) : 1);

    // Sanitize selected theme based on level requirements
    String activeTheme = _selectedTheme;
    if (widget.isCurrentUser) {
      if (activeTheme == 'Golden Legend' && level < 25) {
        activeTheme = 'Default';
      } else if (activeTheme == 'Gold Rush' && level < 10) {
        activeTheme = 'Default';
      } else if (activeTheme == 'Lavender Dusk' && level < 5) {
        activeTheme = 'Default';
      }
    } else {
      if (level >= 25) {
        activeTheme = 'Golden Legend';
      } else if (level >= 10) {
        activeTheme = 'Gold Rush';
      } else if (level >= 5) {
        activeTheme = 'Lavender Dusk';
      } else {
        activeTheme = 'Default';
      }
    }

    final themeGlowColor = activeTheme == 'Default'
        ? sportColor
        : (activeTheme == 'Lavender Dusk'
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
          // Elegant diagonal background accents
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
                // Avatar Frame with dynamic glowing pulsing ring
                Center(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final photoUrl = _publicProfileData?['avatar'] as String? ?? 
                          _publicProfileData?['profile_picture'] as String? ?? 
                          _publicProfileData?['profile_photo'] as String? ?? 
                          (widget.isCurrentUser ? state.user?.profilePhotoUrl : widget.profilePicture);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow border effect
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 146,
                            height: 146,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: _getAvatarBorderColors(level, sportColor),
                              ),
                              boxShadow: [
                                _getAvatarBorderShadow(level, sportColor),
                              ],
                            ),
                          ),
                          
                          // Inner clean gap
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          
                          // Image container
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

                          // Floating Edit Photo Button
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
                                      colors: [sportColor, AppColors.electricCyan],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: sportColor.withValues(alpha: 0.4),
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
                
                // Name, verified check, and country flag
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final userName = _publicProfileData?['name'] as String? ??
                        (widget.isCurrentUser ? (state.user?.name ?? 'Sportigo Champ') : (widget.playerName ?? 'Player'));
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

  Widget _buildThemeSelector(BuildContext context, int level, Color sportColor) {
    if (!widget.isCurrentUser || level < 5) {
      return const SizedBox.shrink();
    }

    final availableThemes = ['Default'];
    if (level >= 5) {
      availableThemes.add('Lavender Dusk');
    }
    if (level >= 10) {
      availableThemes.add('Gold Rush');
    }
    if (level >= 25) {
      availableThemes.add('Golden Legend');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: sportColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profile Theme customization',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: availableThemes.map((themeName) {
                final isSelected = _selectedTheme == themeName;
                Color chipColor = sportColor;
                if (themeName == 'Lavender Dusk') {
                  chipColor = const Color(0xFF8A2BE2);
                } else if (themeName == 'Gold Rush' || themeName == 'Golden Legend') {
                  chipColor = const Color(0xFFD4AF37);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      themeName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _saveSelectedTheme(themeName);
                      }
                    },
                    selectedColor: chipColor,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? chipColor : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, Color sportColor) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final level = _publicProfileData?['stats']?['level'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.level ?? 24) : 1);
        final xp = _publicProfileData?['stats']?['currentLevelXp'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.currentLevelXp ?? 750) : 0);
        final nextXp = _publicProfileData?['stats']?['nextLevelXp'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.nextLevelXp ?? 1000) : 1000);
        final progressPct = _publicProfileData?['stats']?['progressPct'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.progressPct ?? 75) : 0);
        final streak = _publicProfileData?['stats']?['streak'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.streak ?? 7) : 0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: sportColor),
                      const SizedBox(width: 6),
                      Text(
                        'Level $level Player',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$xp / $nextXp XP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // XP linear progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.4),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          height: 10,
                          width: constraints.maxWidth * (progressPct / 100.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [sportColor, AppColors.electricCyan],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Completion meter helper text
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Progress to Level ${level + 1}: $progressPct%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '🔥 $streak Match Winning Streak',
                    style: const TextStyle(
                      color: AppColors.warmOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildConcentricIcon(Color color, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          // Middle circle ring
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          // Inner solid dot
          Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, Color sportColor) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;
    final double childAspectRatio = screenWidth < 360 ? 1.35 : 1.6;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final winRate = _publicProfileData?['stats']?['winRate'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.winRate ?? 72) : 0);
        final primarySport = _publicProfileData?['primary_sport'] as String? ??
            (widget.isCurrentUser ? user?.primarySport : null) ?? 'None';
        final totalGames = _publicProfileData?['stats']?['totalGames'] as int? ??
            (widget.isCurrentUser ? (user?.stats?.totalGames ?? 120) : 0);
        final averageRating = (_publicProfileData?['stats']?['averageRating'] as num?)?.toDouble() ??
            (widget.isCurrentUser ? (user?.stats?.averageRating ?? 0.0) : 0.0);
        final averageRatingStr = averageRating.toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
            children: [
              _buildGlassStatCard(
                context,
                'Win Rate',
                '$winRate%',
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
              ),
              _buildGlassStatCard(
                context,
                'Primary Sport',
                primarySport,
                _buildConcentricIcon(AppColors.electricCyan, 20),
              ),
              _buildGlassStatCard(
                context,
                'Total Games',
                '$totalGames',
                Icon(Icons.sports_soccer, color: sportColor, size: 20),
              ),
              _buildGlassStatCard(
                context,
                'Average Rating',
                '$averageRatingStr ⭐',
                const Icon(Icons.star_border_rounded, color: Colors.amber, size: 20),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildGlassStatCard(
    BuildContext context,
    String title,
    String value,
    Widget iconWidget,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconWidget,
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSportsSection(BuildContext context, Color sportColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 12.0),
          child: Text(
            'Favorite Sports Interests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sportsList.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final sportItem = _sportsList[index];
              final isSelected = _selectedSport == sportItem['name'];
                final dynamicColor = _getSportColor(context, sportItem['name']);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSport = sportItem['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? dynamicColor
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? dynamicColor
                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: dynamicColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(
                        sportItem['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sportItem['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, Color sportColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTabButton(0, 'Activity Log', sportColor),
                const SizedBox(width: 12),
                _buildTabButton(1, 'Achievements', sportColor),
                const SizedBox(width: 12),
                _buildTabButton(2, 'Streaks', sportColor),
              ],
            ),
          ),
        ),
        
        // Tab Content Layout
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildActiveTabContent(sportColor),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, Color sportColor) {
    final isActive = _activeActivityTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeActivityTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? sportColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? sportColor : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Color sportColor) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, matchState) {
        // Collect matches
        final List<MatchModel> matchesList = [];
        if (widget.isCurrentUser) {
          matchesList.addAll(matchState.myMatches);
        } else if (_publicProfileData?['matches'] != null) {
          final matchesJson = _publicProfileData!['matches'] as List<dynamic>;
          matchesList.addAll(
            matchesJson.map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          );
        }

        switch (_activeActivityTab) {
          case 0:
            final activitiesList = <ActivityModel>[];
            if (_publicProfileData != null && _publicProfileData!['activities'] != null) {
              final activitiesJson = _publicProfileData!['activities'] as List<dynamic>;
              activitiesList.addAll(
                activitiesJson.map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
              );
            }

            if (activitiesList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    'No activity yet. Join or organize a match to get started! ⚽',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final displayedActivities = _showAllActivities 
                ? activitiesList 
                : activitiesList.take(3).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: displayedActivities.length,
                    itemBuilder: (context, index) {
                      final activity = displayedActivities[index];
                      final meta = activity.meta ?? {};
                      final sportType = meta['sport_type'] as String? ?? 'Football';
                      final matchTitle = meta['title'] as String? ?? '';
                      final location = meta['location'] as String? ?? '';
                      final dateStr = _formatDateTime(activity.createdAt.toIso8601String());

                      String title = activity.message;
                      if (activity.type == 'match_created') {
                        title = 'Organized $sportType Match';
                      } else if (activity.type == 'match_joined') {
                        title = 'Joined $sportType Match';
                      } else if (activity.type == 'match_left') {
                        title = 'Left $sportType Match';
                      }

                      String subtitle = '';
                      if (matchTitle.isNotEmpty && location.isNotEmpty) {
                        subtitle = '$matchTitle at $location • $dateStr';
                      } else if (matchTitle.isNotEmpty) {
                        subtitle = '$matchTitle • $dateStr';
                      } else {
                        subtitle = '${activity.message} • $dateStr';
                      }

                      final xp = _getActivityXp(activity.type);
                      final sportEmoji = _getSportEmoji(sportType);
                      final dynamicColor = _getSportColor(context, sportType);

                      return _buildTimelineActivity(
                        title: title,
                        subtitle: subtitle,
                        xpReward: '+$xp XP',
                        sportEmoji: sportEmoji,
                        sportColor: dynamicColor,
                      );
                    },
                  ),
                  if (activitiesList.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAllActivities = !_showAllActivities;
                          });
                        },
                        icon: Icon(
                          _showAllActivities ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: sportColor,
                        ),
                        label: Text(
                          _showAllActivities ? 'See Less' : 'See All (${activitiesList.length - 3} more)',
                          style: TextStyle(
                            color: sportColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

          case 1:
            final userForStats = context.read<AuthBloc>().state.user;
            final userLevel = _publicProfileData?['stats']?['level'] as int? ??
                (widget.isCurrentUser ? (userForStats?.stats?.level ?? 1) : 1);
            final userStreak = _publicProfileData?['stats']?['streak'] as int? ??
                (widget.isCurrentUser ? (userForStats?.stats?.streak ?? 0) : 0);
            final userRating = (_publicProfileData?['stats']?['averageRating'] as num?)?.toDouble() ??
                (widget.isCurrentUser ? (userForStats?.stats?.averageRating ?? 0.0) : 0.0);

            final targetUserId = widget.isCurrentUser
                ? context.read<AuthBloc>().state.user?.id
                : widget.userId;

            final pastMatchesList = matchesList.where((m) => m.isPast).toList();
            final createdMatchesCount = pastMatchesList.where((m) => m.creatorId == targetUserId).length;
            final totalPlayedGames = pastMatchesList.length;
            
            // 1. Community Pillar Playstyle calculation
            final createRatio = totalPlayedGames > 0 ? (createdMatchesCount / totalPlayedGames) : 0.0;
            final isCommunityPillar = createRatio >= 0.40;

            // 2. Invincible Streak calculation
            int winStreak = 0;
            final sortedPast = List<MatchModel>.from(pastMatchesList);
            sortedPast.sort((a, b) => b.parsedDateTime.compareTo(a.parsedDateTime));
            for (final m in sortedPast) {
              bool isWin = false;
              try {
                final p = m.participants.firstWhere((part) => part.id == targetUserId);
                if (p.result == 'win') {
                  isWin = true;
                } else if (p.result == 'loss' || p.result == 'draw') {
                  break;
                }
              } catch (_) {
                break;
              }
              if (isWin) {
                winStreak++;
              }
            }
            final finalStreak = winStreak > 0 ? winStreak : userStreak;
            final isInvincible = finalStreak >= 5;

            // 3. Fair Play Ambassador rating calculation
            final isFairPlayAmbassador = userRating >= 4.5 && totalPlayedGames >= 5;

            // 4. Ultimate All-Rounder calculation (3 or more different sport types played)
            final uniqueSportsPlayed = pastMatchesList.map((m) => m.sportType.trim().toLowerCase()).toSet();
            final isAllRounder = uniqueSportsPlayed.length >= 3;

            final List<Map<String, dynamic>> levelMilestones = [
              {
                'level': 1,
                'title': 'Rookie Athlete',
                'req': '0+ XP',
                'desc': "You've taken your first steps on the court. Join local matches to earn XP and level up!",
                'rewards': 'Rookie Badge 👟',
                'badge': '👟',
                'unlocked': userLevel >= 1,
              },
              {
                'level': 2,
                'title': 'Rising Star',
                'req': '1,000+ XP',
                'desc': 'Unlocked for active participants. Your dedication is showing. Unlocks basic profile customization features (like active themes).',
                'rewards': 'Rising Star Badge 💫, Theme Selector',
                'badge': '💫',
                'unlocked': userLevel >= 2,
              },
              {
                'level': 5,
                'title': 'Seasoned Veteran',
                'req': '4,000+ XP',
                'desc': 'Unlocked for experienced players. You have a deep history of matchups. Unlocks the Silver Profile Frame and access to co-hosting matches.',
                'rewards': 'Veteran Badge 🎖️, Silver Frame, Lavender Dusk Theme',
                'badge': '🎖️',
                'unlocked': userLevel >= 5,
              },
              {
                'level': 10,
                'title': 'Elite Competitor',
                'req': '9,000+ XP',
                'desc': 'Unlocked for master players. You are a regular face in the community. Unlocks the Gold Profile Badge and custom status options on your profile card.',
                'rewards': 'Gold Badge 🥇, Gold Rush Theme',
                'badge': '🥇',
                'unlocked': userLevel >= 10,
              },
              {
                'level': 25,
                'title': 'Sportigo Legend',
                'req': '24,000+ XP',
                'desc': 'The ultimate milestone. Reserved for the most dedicated athletes. Unlocks the premium Golden Profile Theme (with custom ambient animations) and high-priority badge on the match lobbies you organize.',
                'rewards': 'Legend Badge 🏆, Golden Theme & Frame, Ambient animations',
                'badge': '🏆',
                'unlocked': userLevel >= 25,
              },
            ];

            final List<Map<String, dynamic>> statBadges = [
              {
                'emoji': '👑',
                'title': 'Community Pillar',
                'req': 'Organize 40%+ of played games',
                'desc': 'Awarded to players who actively bring people together by organizing games. You are the heartbeat of the local sports community!',
                'unlocked': isCommunityPillar,
                'progress': 'Current: ${totalPlayedGames > 0 ? ((createdMatchesCount / totalPlayedGames) * 100).toStringAsFixed(0) : "0"}%',
              },
              {
                'emoji': '🔥',
                'title': 'Invincible',
                'req': 'Win streak of 5+ games',
                'desc': 'Awarded to players on a dominant winning run. There is no stopping you right now!',
                'unlocked': isInvincible,
                'progress': 'Current streak: $finalStreak',
              },
              {
                'emoji': '🤝',
                'title': 'Fair Play Ambassador',
                'req': 'Average rating of 4.5+ (over 5+ games)',
                'desc': 'Awarded for excellent sportsmanship, friendliness, and reliable play style as rated by other community members.',
                'unlocked': isFairPlayAmbassador,
                'progress': 'Rating: ${userRating.toStringAsFixed(1)} ⭐ (Games: $totalPlayedGames)',
              },
              {
                'emoji': '🏅',
                'title': 'Ultimate All-Rounder',
                'req': 'Play 3+ different sport types',
                'desc': "You don't stick to just one game. You dominate across multiple courts and disciplines!",
                'unlocked': isAllRounder,
                'progress': 'Sports: ${uniqueSportsPlayed.length}',
              },
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Level Tiers
                  Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Level Progression Milestones',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: levelMilestones.length,
                    itemBuilder: (context, index) {
                      final milestone = levelMilestones[index];
                      final isUnlocked = milestone['unlocked'] as bool;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: isUnlocked ? 0.75 : 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isUnlocked 
                                ? sportColor.withValues(alpha: 0.3)
                                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                            width: isUnlocked ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: isUnlocked ? 1.0 : 0.4,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isUnlocked ? sportColor : Theme.of(context).colorScheme.surfaceDim).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  milestone['badge'] as String,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Level ${milestone['level']}: ${milestone['title']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isUnlocked
                                              ? Theme.of(context).colorScheme.onSurface
                                              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isUnlocked ? AppColors.sportsGreen : Colors.grey).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isUnlocked ? 'UNLOCKED' : 'LOCKED',
                                          style: TextStyle(
                                            color: isUnlocked ? AppColors.sportsGreen : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Requirement: ${milestone['req']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sportColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    milestone['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnlocked 
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Rewards: ${milestone['rewards']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isUnlocked
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Special Badges
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Stat-Based Achievements',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: statBadges.length,
                    itemBuilder: (context, index) {
                      final badge = statBadges[index];
                      final isUnlocked = badge['unlocked'] as bool;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: isUnlocked ? 0.75 : 0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isUnlocked 
                                ? sportColor.withValues(alpha: 0.3)
                                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                            width: isUnlocked ? 1.5 : 1,
                          ),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: sportColor.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Opacity(
                                  opacity: isUnlocked ? 1.0 : 0.4,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isUnlocked ? sportColor : Theme.of(context).colorScheme.surfaceDim).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      badge['emoji'] as String,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isUnlocked ? AppColors.sportsGreen : Colors.grey).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isUnlocked ? 'ACTIVE' : 'LOCKED',
                                    style: TextStyle(
                                      color: isUnlocked ? AppColors.sportsGreen : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              badge['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isUnlocked
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              badge['req'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: sportColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                badge['desc'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isUnlocked 
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                  height: 1.3,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badge['progress'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );

          case 2:
            final streakVal = _publicProfileData?['stats']?['streak'] as int? ??
                (widget.isCurrentUser ? (context.read<AuthBloc>().state.user?.stats?.streak ?? 0) : 0);

            // Calculate played weekdays for the selected week
            final playedWeekdays = <int>{};
            final now = DateTime.now();
            final selectedWeekStart = now.subtract(Duration(days: now.weekday - 1 - (_selectedWeekOffset * 7)));
            final selectedWeekMonday = DateTime(selectedWeekStart.year, selectedWeekStart.month, selectedWeekStart.day);
            final selectedWeekSunday = selectedWeekMonday.add(const Duration(days: 7));

            for (final match in matchesList) {
              if (match.isPast) {
                final matchDate = match.parsedDateTime.toLocal();
                if (matchDate.isAfter(selectedWeekMonday.subtract(const Duration(seconds: 1))) && 
                    matchDate.isBefore(selectedWeekSunday)) {
                  playedWeekdays.add(matchDate.weekday);
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🔥 ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$streakVal Match Winning Streak',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Keep playing matches to grow your streak!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2F9E44),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedWeekOffset--;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  color: Colors.transparent,
                                  child: const Text(
                                    '◀',
                                    style: TextStyle(color: Color(0xFF495057), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getWeekLabel(_selectedWeekOffset),
                                style: const TextStyle(
                                  color: Color(0xFF495057),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _selectedWeekOffset < 0
                                    ? () {
                                        setState(() {
                                          _selectedWeekOffset++;
                                        });
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  color: Colors.transparent,
                                  child: Text(
                                    '▶',
                                    style: TextStyle(
                                      color: _selectedWeekOffset < 0 ? const Color(0xFF495057) : const Color(0xFFADB5BD),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStreakDay('M', playedWeekdays.contains(DateTime.monday)),
                        _buildStreakDay('T', playedWeekdays.contains(DateTime.tuesday)),
                        _buildStreakDay('W', playedWeekdays.contains(DateTime.wednesday)),
                        _buildStreakDay('T', playedWeekdays.contains(DateTime.thursday)),
                        _buildStreakDay('F', playedWeekdays.contains(DateTime.friday)),
                        _buildStreakDay('S', playedWeekdays.contains(DateTime.saturday)),
                        _buildStreakDay('S', playedWeekdays.contains(DateTime.sunday)),
                      ],
                    ),
                  ],
                ),
              ),
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildTimelineActivity({
    required String title,
    required String subtitle,
    required String xpReward,
    required String sportEmoji,
    required Color sportColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sportColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              sportEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sportsGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              xpReward,
              style: const TextStyle(
                color: AppColors.sportsGreen,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStreakDay(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF2B8A3E) : const Color(0xFFF1F3F5),
          ),
          child: Center(
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 14,
              color: active ? Colors.white : const Color(0xFF868E96),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF868E96),
          ),
        ),
      ],
    );
  }

  int _getActivityXp(String type) {
    if (type == 'match_created') return 20;
    if (type == 'match_joined') return 5;
    return 0;
  }


  String _getSportEmoji(String sport) {
    switch (sport) {
      case 'Football':
        return '⚽';
      case 'Cricket':
        return '🏏';
      case 'Badminton':
        return '🏸';
      case 'Basketball':
        return '🏀';
      case 'Tennis':
        return '🎾';
      case 'Padel':
        return '🏓';
      default:
        return '🏃';
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _getWeekLabel(int offset) {
    if (offset == 0) return 'THIS WEEK';
    if (offset == -1) return 'LAST WEEK';
    
    final now = DateTime.now();
    final targetWeekStart = now.subtract(Duration(days: now.weekday - 1 - (offset * 7)));
    final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
    
    final startStr = DateFormat('MMM d').format(targetWeekStart);
    final endStr = DateFormat('MMM d').format(targetWeekEnd);
    return '$startStr - $endStr'.toUpperCase();
  }
}
