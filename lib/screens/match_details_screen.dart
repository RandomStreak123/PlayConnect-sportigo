import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../data/models/match_model.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../data/repositories/match_repository.dart';
import '../core/di/service_locator.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import 'match_details/widgets/match_header_image.dart';
import 'match_details/widgets/match_primary_info.dart';
import 'match_details/widgets/match_schedule_location.dart';
import 'match_details/widgets/match_participants_list.dart';
import 'match_details/widgets/match_action_buttons.dart';

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
      final repo = getIt<MatchRepository>();
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

    return _buildScaffold(context);
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
          MatchHeaderImage(match: _match),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MatchPrimaryInfo(match: _match),
                  const SizedBox(height: AppSpacing.lg),
                  MatchScheduleLocation(match: _match),
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
                  MatchParticipantsList(match: _match),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      bottomNavigationBar: MatchActionButtons(
        match: _match,
        fromPastMatches: widget.fromPastMatches,
        onMatchUpdated: (updatedMatch) {
          setState(() {
            _match = updatedMatch;
          });
        },
      ),
    );
  }
}
