import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../core/constants/colors.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/matches/match_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_icon_size.dart';
import 'record_results_sheet.dart';
import 'rate_players_sheet.dart';

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
      final repo = getIt<MatchRepository>();
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

  void _showRecordResultsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RecordResultsSheet(
          match: _matchState,
          onSave: (resultsPayload) {
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
        );
      },
    );
  }

  void _showRatePlayersBottomSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RatePlayersSheet(
          match: _matchState,
          currentUserId: userId,
          onSave: (ratingsPayload) {
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
            final isCreator = (_matchState.creatorId != null && _matchState.creatorId == userId) ||
                (authState.user != null && _matchState.organizer == authState.user?.name);
            final isFull = _matchState.joinedCount >= _matchState.maxSlots;
            
            bool isJoined = _matchState.isJoinedBy(userId);
            if (_isSubmitting && _pendingAction == 'join') {
              isJoined = false;
            } else if (_isSubmitting && _pendingAction == 'leave') {
              isJoined = true;
            }

            if (_isSubmitting && (_pendingAction == 'recordResults' || _pendingAction == 'submitRatings')) {
              return const SizedBox(
                height: 52,
                child: Center(child: AppLoadingIndicator()),
              );
            }

            if (_matchState.isPast) {
              return _buildPastMatchActions(context, isCreator, isJoined);
            }

            return _buildActiveMatchActions(
              context: context,
              user: authState.user,
              isJoined: isJoined,
              isCreator: isCreator,
              isFull: isFull,
              isRestricted: isRestricted,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPastMatchActions(BuildContext context, bool isCreator, bool isJoined) {
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

  Widget _buildActiveMatchActions({
    required BuildContext context,
    required UserModel? user,
    required bool isJoined,
    required bool isCreator,
    required bool isFull,
    required bool isRestricted,
  }) {
    if (isJoined && !isCreator) {
      return OutlinedButton(
        onPressed: _isSubmitting
            ? null
            : () {
                setState(() {
                  _isSubmitting = true;
                  _pendingAction = 'leave';
                });
                context.read<MatchBloc>().add(MatchLeft(matchId: _matchState.id, userId: user!.id));
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: _isSubmitting && _pendingAction == 'leave'
            ? SizedBox(
                height: 20,
                width: 20,
                child: AppLoadingIndicator(color: Theme.of(context).colorScheme.error),
              )
            : const Text(
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
              style: const TextStyle(
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
            const Text(
              '🌸 Women-Only Match',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFFF4D8D),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isSubmitting
          ? null
          : () {
              setState(() {
                _isSubmitting = true;
                _pendingAction = 'join';
              });
              context.read<MatchBloc>().add(MatchJoined(matchId: _matchState.id, user: user!));
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
      child: _isSubmitting && _pendingAction == 'join'
          ? const SizedBox(
              height: 20,
              width: 20,
              child: AppLoadingIndicator(color: Colors.white),
            )
          : Text(
              'Join Match (${_matchState.slotsLeft} spots left)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
    );
  }
}
