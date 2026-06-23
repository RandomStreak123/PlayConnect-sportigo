import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/app_loading_indicator.dart';
import '../../../../core/constants/colors.dart';
import '../../../../logic/blocs/auth/auth_bloc.dart';
import '../../../../logic/blocs/matches/match_bloc.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../core/utils/avatar_image_helper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_icon_size.dart';

class MatchActionButtons extends StatefulWidget {
  final MatchModel match;
  final bool fromPastMatches;
  final Function(MatchModel) onMatchUpdated;

  const MatchActionButtons({
    super.key,
    required this.match,
    required this.fromPastMatches,
    required this.onMatchUpdated,
  });

  @override
  State<MatchActionButtons> createState() => _MatchActionButtonsState();
}

class _MatchActionButtonsState extends State<MatchActionButtons> {
  bool _isSubmitting = false;
  String? _pendingAction;
  bool _hasRated = false;
  late MatchModel _matchState;

  @override
  void initState() {
    super.initState();
    _matchState = widget.match;
    _checkIfUserHasRated();
  }

  @override
  void didUpdateWidget(MatchActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match != widget.match) {
      setState(() {
        _matchState = widget.match;
      });
      _checkIfUserHasRated();
    }
  }

  void _checkIfUserHasRated() async {
    try {
      final repo = context.read<MatchRepository>();
      final currentUserId = context.read<AuthBloc>().state.user?.id;
      final ratingsList = await repo.getRatings(_matchState.id);
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

  MatchModel? _findUpdatedMatch(MatchState state) {
    for (final m in [...state.matches, ...state.myMatches]) {
      if (m.id == _matchState.id) return m;
    }
    return null;
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
      for (var p in _matchState.participants) p.id: p.result ?? '',
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
                      itemCount: _matchState.participants.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _matchState.participants[index];
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
                                    matchId: _matchState.id,
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
    final rateableParticipants = _matchState.participants.where((p) => p.id != userId).toList();

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
                                          matchId: _matchState.id,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listenWhen: (previous, current) => current.message != null,
      listener: (context, state) {
        if (!_isSubmitting || _pendingAction == null) return;

        final updated = _findUpdatedMatch(state);
        if (updated != null) {
          setState(() {
            _matchState = updated;
          });
          widget.onMatchUpdated(updated);
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
      child: Container(
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
            final isRestricted = _matchState.womenOnly && userGender != 'female';
            final isJoined = _matchState.isJoinedBy(userId);
            final isCreator = (_matchState.creatorId != null && _matchState.creatorId == userId) ||
                (authState.user != null && _matchState.organizer == authState.user?.name);
            final isFull = _matchState.joinedCount >= _matchState.maxSlots;

            if (_isSubmitting) {
              return const SizedBox(
                height: 52,
                child: Center(child: AppLoadingIndicator()),
              );
            }

            if (_matchState.isPast) {
              if (widget.fromPastMatches) {
                final hasResults = _matchState.participants.any((p) => p.result != null && p.result!.isNotEmpty);
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
                  context.read<MatchBloc>().add(MatchLeft(_matchState.id));
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
                context.read<MatchBloc>().add(MatchJoined(_matchState.id));
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
                'Join Match (${_matchState.slotsLeft} spots left)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}
