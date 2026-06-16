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
  final bool fromPastMatches;

  const MatchDetailsScreen({
    super.key,
    this.match,
    this.matchId,
    this.fromPastMatches = false,
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
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    if (widget.match != null) {
      _match = widget.match!;
      _isInitialized = true;
      _checkIfUserHasRated();
    } else if (widget.matchId != null) {
      _loadMatchDetails();
    }
  }

  void _checkIfUserHasRated() async {
    try {
      final repo = context.read<MatchRepository>();
      final currentUserId = context.read<AuthBloc>().state.user?.id;
      final ratingsList = await repo.getRatings(_match.id);
      if (mounted) {
        setState(() {
          _hasRated = ratingsList.any((r) {
            final raterId = r['rater_id'];
            final raterObj = r['rater'];
            return raterId == currentUserId || (raterObj != null && raterObj['id'] == currentUserId);
          });
        });
      }
    } catch (_) {
      // Fail silently
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
        _checkIfUserHasRated();
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
          if (_pendingAction == 'recordResults' || _pendingAction == 'submitRatings') {
            context.read<AuthBloc>().add(const AuthCheckRequested(forceRefresh: true));
          }
          if (_pendingAction == 'submitRatings') {
            setState(() {
              _hasRated = true;
            });
          }
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

            if (_match.isPast) {
              if (widget.fromPastMatches) {
                final hasResults = _match.participants.any((p) => p.result != null && p.result!.isNotEmpty);
                if (isCreator) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: hasResults ? null : () => _showRecordResultsBottomSheet(context),
                            icon: const Icon(Icons.emoji_events, size: 20),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                hasResults ? 'Results Updated' : 'Update Results',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _hasRated ? null : () => _showRatePlayersBottomSheet(context),
                            icon: const Icon(Icons.star, size: 20),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _hasRated ? 'Ratings Submitted' : 'Rate Players',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warmOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (isJoined) {
                  return SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasRated ? null : () => _showRatePlayersBottomSheet(context),
                      icon: const Icon(Icons.star, size: 20),
                      label: Text(_hasRated ? 'Ratings Submitted' : 'Rate Players', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  );
                }
              }
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
                      'MATCH COMPLETED',
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
              userId: participant.id,
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
                      Flexible(
                        child: Text(
                          participant.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
            if (participant.result != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _buildResultBadge(context, participant.result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultBadge(BuildContext context, String result) {
    Color bgColor;
    Color textColor;
    String label;

    switch (result.toLowerCase()) {
      case 'win':
        bgColor = const Color(0xFFE8F5E9); // light green
        textColor = const Color(0xFF2E7D32); // dark green
        label = 'Win';
        break;
      case 'loss':
        bgColor = const Color(0xFFFFEBEE); // light red
        textColor = const Color(0xFFC62828); // dark red
        label = 'Loss';
        break;
      case 'draw':
        bgColor = const Color(0xFFECEFF1); // light grey/blue-grey
        textColor = const Color(0xFF37474F); // dark grey/blue-grey
        label = 'Draw';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  void _showRecordResultsBottomSheet(BuildContext context) {
    final Map<int, String> playerResults = {
      for (var p in _match.participants) p.id: p.result ?? '',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              padding: EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Record Match Results',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap Win, Loss, or Draw for each player. Tap again to deselect.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _match.participants.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _match.participants[index];
                        final currentResult = playerResults[p.id] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              AvatarImageHelper.circleAvatar(
                                path: p.profilePicture,
                                radius: 20,
                                backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildToggleChip(
                                    label: 'Win',
                                    selected: currentResult == 'win',
                                    selectedColor: const Color(0xFF2E7D32),
                                    onTap: () {
                                      setModalState(() {
                                        playerResults[p.id] = currentResult == 'win' ? '' : 'win';
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _buildToggleChip(
                                    label: 'Loss',
                                    selected: currentResult == 'loss',
                                    selectedColor: const Color(0xFFC62828),
                                    onTap: () {
                                      setModalState(() {
                                        playerResults[p.id] = currentResult == 'loss' ? '' : 'loss';
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  _buildToggleChip(
                                    label: 'Draw',
                                    selected: currentResult == 'draw',
                                    selectedColor: const Color(0xFF546E7A),
                                    onTap: () {
                                      setModalState(() {
                                        playerResults[p.id] = currentResult == 'draw' ? '' : 'draw';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final resultsPayload = playerResults.entries
                                .where((e) => e.value.isNotEmpty)
                                .map((e) => {'user_id': e.key, 'result': e.value})
                                .toList();

                            setState(() {
                              _isSubmitting = true;
                              _pendingAction = 'recordResults';
                            });

                            context.read<MatchBloc>().add(
                                  MatchResultsRecorded(
                                    matchId: _match.id,
                                    results: resultsPayload,
                                  ),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Save Results'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatePlayersBottomSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;
    final rateableParticipants = _match.participants.where((p) => p.id != userId).toList();

    final Map<int, int> playerRatings = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              padding: EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Text(
                        '⭐',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Rate Players',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rate each player from 1 to 5 stars. You earn +10 XP per player rated!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (rateableParticipants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No other players to rate.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rateableParticipants.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = rateableParticipants[index];
                          final currentRating = playerRatings[p.id] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Row(
                              children: [
                                AvatarImageHelper.circleAvatar(
                                  path: p.profilePicture,
                                  radius: 20,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (starIndex) {
                                    final starVal = starIndex + 1;
                                    final isSelected = currentRating >= starVal;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          playerRatings[p.id] = starVal;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: Icon(
                                          isSelected ? Icons.star : Icons.star_border,
                                          color: isSelected ? Colors.amber : Colors.grey.shade300,
                                          size: 28,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: rateableParticipants.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  final ratingsPayload = playerRatings.entries
                                      .where((e) => e.value > 0)
                                      .map((e) => {'user_id': e.key, 'rating': e.value})
                                      .toList();

                                  setState(() {
                                    _isSubmitting = true;
                                    _pendingAction = 'submitRatings';
                                  });

                                  context.read<MatchBloc>().add(
                                        MatchRatingsSubmitted(
                                          matchId: _match.id,
                                          ratings: ratingsPayload,
                                        ),
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warmOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: const Text('Submit Ratings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
