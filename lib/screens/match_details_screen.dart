import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../widgets/app_loading_indicator.dart';
import '../data/models/match_model.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/matches/match_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/player_reveal_card.dart';
import '../core/utils/sport_image_helper.dart';
import '../core/utils/avatar_image_helper.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';
import '../data/repositories/match_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


class MatchDetailsScreen extends StatefulWidget {
  final MatchModel? match;
  final String? matchId;

  const MatchDetailsScreen({
    super.key,
    this.match,
    this.matchId,
  }) : assert(match != null || matchId != null, 'Either match or matchId must be provided');

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  late MatchModel _match;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  String? _pendingAction;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      _match = widget.match!;
      _isInitialized = true;
    } else if (widget.matchId != null) {
      _loadMatchDetails();
    }
  }

  void _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<MatchRepository>();
      final match = await repo.getMatch(widget.matchId!);
      if (mounted) {
        setState(() {
          _match = match;
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  MatchModel? _findUpdatedMatch(MatchState state) {
    if (!_isInitialized) return null;
    for (final m in [...state.matches, ...state.myMatches]) {
      if (m.id == _match.id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: _isLoading
              ? const AppLoadingIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Failed to load match details.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadMatchDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return BlocListener<MatchBloc, MatchState>(
      listenWhen: (previous, current) => current.message != null,
      listener: (context, state) {
        if (!_isSubmitting || _pendingAction == null) return;

        final updated = _findUpdatedMatch(state);
        if (updated != null) {
          setState(() => _match = updated);
        }

        if (state.isActionSuccess) {
          setState(() {
            _isSubmitting = false;
            _pendingAction = null;
          });
        } else {
          setState(() {
            _isSubmitting = false;
            _pendingAction = null;
          });
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;
    final userGender = authState.user?.gender;
    final isRestricted = _match.womenOnly && userGender != 'female';
    final isJoined = _match.isJoinedBy(userId);
    final isCreator = (_match.creatorId != null && _match.creatorId == userId) ||
        (authState.user != null && _match.organizer == authState.user?.name);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(SportImageHelper.getImageForSport(_match.sportType), fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Theme.of(context).colorScheme.surface],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      final shareUrl = 'https://sportigo.com/matches/${_match.id}';
                      Share.share(
                        'Join my ${_match.sportType} match "${_match.title}" at ${_match.location}! $shareUrl',
                        subject: 'Join my Sportigo match!',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          _match.sportType.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceDim,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          _match.skillLevel,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      if (_match.womenOnly) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs + 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4D8D), Color(0xFF7B61FF)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D8D).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                'Women Only',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Women-Only safety notice
                  if (_match.womenOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF4D8D).withValues(alpha: 0.08),
                              const Color(0xFF7B61FF).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: const Color(0xFFFF4D8D).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xxs + 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D8D).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFFFF4D8D),
                                size: AppIconSize.xs,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'This is a safe, women-only match. Only verified female players can join.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFFF4D8D),
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _match.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailRow(
                    context,
                    Icons.calendar_today_outlined,
                    _match.dateTime,
                    _match.skillLevel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    context,
                    Icons.location_on_outlined,
                    _match.location,
                    '${_match.slotsLeft} slots open • Click to view on Google Maps',
                    onTap: () async {
                      String searchQuery = _match.location;
                      if (!searchQuery.toLowerCase().contains('trivandrum') &&
                          !searchQuery.toLowerCase().contains('thiruvananthapuram')) {
                        searchQuery += ', Thiruvananthapuram';
                      }
                      final Uri url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}',
                      );
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        try {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open map.')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'About this Match',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Join fellow players for a ${_match.sportType} session at ${_match.location}. '
                    'Skill level: ${_match.skillLevel}. Arrive a few minutes early to warm up.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Players (${_match.joinedCount}/${_match.maxSlots})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_match.participants.isEmpty)
                    Text(
                      'No players listed yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._match.participants.map(
                      (p) => _buildPlayerRow(
                        context,
                        p,
                        p.id == _match.creatorId,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (!isCreator && !isJoined && !isRestricted && _match.slotsLeft > 0 && _match.joinedCount < _match.maxSlots)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Theme.of(context).colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'This spot is waiting for you!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.bottomNavClearance),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -5),
              blurRadius: 10,
            ),
          ],
        ),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final userId = authState.user?.id;
            final userGender = authState.user?.gender;
            final isRestricted = _match.womenOnly && userGender != 'female';
            final isJoined = _match.isJoinedBy(userId);
            final isCreator = (_match.creatorId != null && _match.creatorId == userId) ||
                (authState.user != null && _match.organizer == authState.user?.name);
            final isFull = _match.joinedCount >= _match.maxSlots;

            if (_isSubmitting) {
              return const SizedBox(
                height: 52,
                child: Center(child: AppLoadingIndicator()),
              );
            }

            if (isJoined && !isCreator) {
              return OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSubmitting = true;
                    _pendingAction = 'leave';
                  });
                  context.read<MatchBloc>().add(MatchLeft(_match.id));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text(
                  'Leave Match',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            }

            if (isJoined || isCreator) {
              return SizedBox(
                height: 52,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.sportsGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      isCreator ? 'You created this match' : 'You joined this match',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.sportsGreen,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (isFull) {
              return SizedBox(
                height: 52,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      'MATCH FULL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (isRestricted) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF4D8D).withValues(alpha: 0.1),
                      const Color(0xFF7B61FF).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: const Color(0xFFFF4D8D).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFFF4D8D), size: AppIconSize.xs + 2),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '🌸 Women-Only Match',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFFFF4D8D),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _isSubmitting = true;
                  _pendingAction = 'join';
                });
                context.read<MatchBloc>().add(MatchJoined(_match.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: Text(
                'Join Match (${_match.slotsLeft} spots left)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F172A), // Dark navy pin icon matching image
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    MatchParticipant participant,
    bool isOrganizer,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlayerRevealCard(
              playerName: participant.name,
              sportType: _match.sportType,
              profilePicture: participant.profilePicture,
            ),
          );
        },
        child: Row(
          children: [
            AvatarImageHelper.circleAvatar(
              path: participant.profilePicture,
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        participant.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.xxs),
                          ),
                          child: Text(
                            'Organizer',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.warmOrange,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _match.skillLevel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
