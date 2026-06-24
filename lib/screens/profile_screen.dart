import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile/utils/profile_theme_helper.dart';
import '../core/constants/colors.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../core/di/service_locator.dart';
import '../data/repositories/activity_repository.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'profile/widgets/profile_custom_app_bar.dart';
import 'profile/widgets/profile_card.dart';
import 'profile/widgets/level_section.dart';
import 'profile/widgets/theme_selector.dart';
import 'profile/widgets/stat_grid.dart';
import 'profile/widgets/sports_section.dart';
import 'profile/widgets/activity_section.dart';
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
  String _selectedSport = 'Football';
  late AnimationController _animationController;
  late ScrollController _scrollController;
  String _selectedTheme = 'Default';

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
    final savedTheme = await ProfileThemeHelper.loadSelectedTheme();
    if (mounted) {
      setState(() {
        _selectedTheme = savedTheme;
      });
    }
  }

  Future<void> _saveSelectedTheme(String themeName) async {
    await ProfileThemeHelper.saveSelectedTheme(themeName);
    if (mounted) {
      setState(() {
        _selectedTheme = themeName;
      });
    }
  }

  Future<void> _loadPublicProfileWithId(int userId, {bool isRefresh = false}) async {
    if (widget.isCurrentUser) {
      final currentUser = context.read<AuthBloc>().state.user;
      if (currentUser == null) return;

      setState(() {
        _publicProfileData = {
          'id': currentUser.id,
          'name': currentUser.name,
          'username': currentUser.username,
          'email': currentUser.email,
          'phone': currentUser.phoneNumber,
          'gender': currentUser.gender,
          'avatar': currentUser.profilePicture,
          'bio': currentUser.bio,
          'primary_sport': currentUser.primarySport,
          'skill_tier': currentUser.skillTier,
          'stats': _publicProfileData?['stats'] ?? currentUser.stats?.toJson(),
          'matches': _publicProfileData?['matches'],
          'activities': _publicProfileData?['activities'],
        };
      });

      try {
        final authRepository = getIt<AuthRepository>();
        final activityRepository = getIt<ActivityRepository>();

        await Future.wait([
          authRepository.getUserStats().then((stats) {
            if (mounted) {
              setState(() {
                _publicProfileData = {
                  ...?_publicProfileData,
                  'stats': stats.toJson(),
                };
                
                final level = stats.level;
                String theme = 'Default';
                if (level >= 25) {
                  theme = 'Golden Legend';
                } else if (level >= 10) {
                  theme = 'Gold Rush';
                } else if (level >= 5) {
                  theme = 'Lavender Dusk';
                }
                _loadSelectedTheme().then((_) {
                  if (_selectedTheme == 'Default' || _selectedTheme.isEmpty) {
                    setState(() {
                      _selectedTheme = theme;
                    });
                  }
                });
              });
            }
          }),
          authRepository.getUserHistory().then((history) {
            if (mounted) {
              setState(() {
                _publicProfileData = {
                  ...?_publicProfileData,
                  'matches': history.map((m) => m.toJson()).toList(),
                };
              });
            }
          }),
          activityRepository.getActivities().then((res) {
            if (mounted) {
              setState(() {
                _publicProfileData = {
                  ...?_publicProfileData,
                  'activities': res.activities.map((a) => a.toJson()).toList(),
                };
              });
            }
          }),
        ]);
      } catch (e) {
        try {
          if (!mounted) return;
          final authRepository = getIt<AuthRepository>();
          final data = await authRepository.getPublicProfile(userId);
          if (mounted) {
            setState(() {
              _publicProfileData = data;
            });
          }
        } catch (_) {}
      }
      return;
    }

    final shouldShowLoader = !isRefresh && _publicProfileData == null && !widget.isCurrentUser;
    if (shouldShowLoader) {
      setState(() {
        _publicProfileError = null;
      });
    }
    try {
      final authRepository = getIt<AuthRepository>();
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
          _selectedTheme = theme;
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

    final premiumColors = ProfileThemeHelper.getGradient(activeTheme);
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
                        ProfileCustomAppBar(isCurrentUser: widget.isCurrentUser),
                        
                        ProfileCard(
                          isCurrentUser: widget.isCurrentUser,
                          playerName: widget.playerName,
                          profilePicture: widget.profilePicture,
                          userId: widget.userId,
                          publicProfileData: _publicProfileData,
                          selectedTheme: activeTheme,
                          sportColor: sportColor,
                          onPhotoUploaded: (updatedUser) {
                            final uid = widget.isCurrentUser
                                ? context.read<AuthBloc>().state.user?.id
                                : widget.userId;
                            if (uid != null) {
                              _loadPublicProfileWithId(uid, isRefresh: true);
                            }
                          },
                        ),
                        
                        LevelSection(
                          isCurrentUser: widget.isCurrentUser,
                          publicProfileData: _publicProfileData,
                          sportColor: sportColor,
                        ),

                        ThemeSelector(
                          isCurrentUser: widget.isCurrentUser,
                          level: levelForTheme,
                          sportColor: sportColor,
                          selectedTheme: _selectedTheme,
                          onThemeChanged: (themeName) => _saveSelectedTheme(themeName),
                        ),
                        
                        StatGrid(
                          isCurrentUser: widget.isCurrentUser,
                          publicProfileData: _publicProfileData,
                          sportColor: sportColor,
                        ),
                        
                        SportsSection(
                          selectedSport: _selectedSport,
                          onSportSelected: (sport) {
                            setState(() {
                              _selectedSport = sport;
                            });
                          },
                          sportsList: _sportsList,
                        ),
                        
                        ActivitySection(
                          isCurrentUser: widget.isCurrentUser,
                          userId: widget.userId,
                          publicProfileData: _publicProfileData,
                          sportColor: sportColor,
                        ),
                        
                        const SizedBox(height: 100),
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
}
