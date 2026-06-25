import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_loading_indicator.dart';
import '../data/models/activity_model.dart';
import '../logic/blocs/activity/activity_bloc.dart';
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

  void _handleActivityTap(ActivityModel activity) {
    final meta = activity.meta;
    if (meta == null) return;

    final matchId = meta['match_id']?.toString() ?? meta['match_id'];
    if (matchId != null) {
      context.push('/match-details?id=$matchId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: SafeArea(
        child: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state.status == ActivityStatus.initial ||
                (state.status == ActivityStatus.loading && state.activities.isEmpty)) {
              return const ActivityShimmerLoader();
            }

            if (state.status == ActivityStatus.failure) {
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
    );
  }
}
