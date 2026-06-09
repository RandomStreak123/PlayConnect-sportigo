import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_loading_indicator.dart';
import '../core/constants/colors.dart';
import '../core/utils/avatar_image_helper.dart';
import '../data/models/activity_model.dart';
import '../data/repositories/match_repository.dart';
import '../logic/blocs/activity/activity_bloc.dart';
import 'match_details_screen.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';

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

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs hr${hrs > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Return simple date e.g. May 21
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  Color _getActivityColor(String type, String? sportType) {
    if (type == 'match_created') {
      return AppColors.sportsGreen;
    } else if (type == 'match_joined') {
      switch (sportType?.toLowerCase()) {
        case 'football':
          return const Color(0xFF4CAF50);
        case 'basketball':
          return const Color(0xFFFF9800);
        case 'tennis':
          return const Color(0xFFCDDC39);
        case 'badminton':
          return const Color(0xFF00BCD4);
        case 'cricket':
          return const Color(0xFF3F51B5);
        default:
          return AppColors.sportsGreen;
      }
    } else if (type == 'match_left') {
      return Colors.redAccent;
    }
    return AppColors.deepBlue;
  }

  Widget _getActivityIcon(String type, String? sportType, Color color) {
    IconData iconData;
    if (type == 'match_created') {
      iconData = Icons.add_circle_outline;
    } else if (type == 'match_left') {
      iconData = Icons.exit_to_app_rounded;
    } else {
      // Joined
      switch (sportType?.toLowerCase()) {
        case 'football':
          iconData = Icons.sports_soccer_rounded;
          break;
        case 'basketball':
          iconData = Icons.sports_basketball_rounded;
          break;
        case 'tennis':
          iconData = Icons.sports_tennis_rounded;
          break;
        case 'badminton':
          iconData = Icons.sports_tennis; // Icon for badminton
          break;
        case 'cricket':
          iconData = Icons.sports_cricket_rounded;
          break;
        default:
          iconData = Icons.sports_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Icon(iconData, color: color, size: AppIconSize.md),
    );
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
                return _buildShimmerLoader();
              }

              if (state.status == ActivityStatus.failure && state.activities.isEmpty) {
                return _buildErrorState(state.errorMessage ?? 'An error occurred');
              }

              if (state.activities.isEmpty) {
                return _buildEmptyState();
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
                    return _buildActivityCard(activity);
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

  Widget _buildActivityCard(ActivityModel activity) {
    final meta = activity.meta;
    final sportType = meta?['sport_type'] as String?;
    final color = _getActivityColor(activity.type, sportType);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: meta != null && meta['match_id'] != null ? () => _handleActivityTap(activity) : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Avatar
                  AvatarImageHelper.circleAvatar(
                    path: activity.user?.profilePicture,
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activity.user?.name ?? 'Player',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getRelativeTime(activity.createdAt),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activity.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        if (meta != null && meta['location'] != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: AppIconSize.xs,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Expanded(
                                child: Text(
                                  meta['location'].toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Sport Icon Indicator
                  _getActivityIcon(activity.type, sportType, color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Shimmer
              _buildShimmerBlock(48, 48, radius: 24),
              const SizedBox(width: AppSpacing.sm + 2),

              // Content Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBlock(80, 14, radius: AppRadius.xxs),
                        _buildShimmerBlock(40, 10, radius: AppRadius.xxs),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildShimmerBlock(double.infinity, 14, radius: AppRadius.xxs),
                    const SizedBox(height: 6),
                    _buildShimmerBlock(160, 14, radius: AppRadius.xxs),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),

              // Icon Shimmer
              _buildShimmerBlock(44, 44, radius: 22),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBlock(double width, double height, {double radius = AppRadius.xs}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceDim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dynamic_feed_rounded,
                size: AppIconSize.hero,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Activity Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start by creating or joining matches to build the sports community!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh to check for items
                context.read<ActivityBloc>().add(const ActivityFetched());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: AppIconSize.xl, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load activities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.read<ActivityBloc>().add(const ActivityFetched());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
