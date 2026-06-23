import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../data/models/activity_model.dart';
import '../data/repositories/match_repository.dart';
import '../logic/blocs/activity/activity_bloc.dart';
import 'match_details_screen.dart';
import '../core/theme/app_spacing.dart';
import 'activity_feed/widgets/activity_card.dart';
import 'activity_feed/widgets/activity_empty_state.dart';
import 'activity_feed/widgets/activity_error_state.dart';
import 'activity_feed/widgets/activity_shimmer_loader.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMatch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Trigger initial fetch when screen mounts
    context.read<ActivityBloc>().add(const ActivityFetched());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ActivityBloc>().add(const ActivityFetchedMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _handleActivityTap(ActivityModel activity) async {
    final meta = activity.meta;
    if (meta == null) return;

    final matchId = meta['match_id']?.toString() ?? meta['match_id'];
    if (matchId == null) return;

    setState(() {
      _isLoadingMatch = true;
    });

    try {
      final matchRepository = RepositoryProvider.of<MatchRepository>(context);
      final match = await matchRepository.getMatch(matchId);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(match: match),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load match details: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMatch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Sports Feed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            centerTitle: false,
          ),
          body: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state.status == ActivityStatus.initial ||
                  (state.status == ActivityStatus.loading && state.activities.isEmpty)) {
                return const ActivityShimmerLoader();
              }

              if (state.status == ActivityStatus.failure && state.activities.isEmpty) {
                return ActivityErrorState(
                  message: state.errorMessage ?? 'An error occurred',
                  onRetry: () {
                    context.read<ActivityBloc>().add(const ActivityFetched());
                  },
                );
              }

              if (state.activities.isEmpty) {
                return ActivityEmptyState(
                  onRefresh: () {
                    context.read<ActivityBloc>().add(const ActivityFetched());
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ActivityBloc>().add(const ActivityFetched());
                },
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  itemCount: state.hasMore ? state.activities.length + 1 : state.activities.length,
                  itemBuilder: (context, index) {
                    if (index >= state.activities.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: AppLoadingIndicator(),
                        ),
                      );
                    }

                    final activity = state.activities[index];
                    final meta = activity.meta;
                    return ActivityCard(
                      activity: activity,
                      onTap: meta != null && meta['match_id'] != null ? () => _handleActivityTap(activity) : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_isLoadingMatch)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLoadingIndicator(color: Colors.white),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading match details...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
