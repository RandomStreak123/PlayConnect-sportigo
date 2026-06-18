import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_icon_size.dart';
import '../core/theme/app_radius.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/match_repository.dart';
import '../logic/blocs/notification/notification_bloc.dart';
import '../logic/blocs/notification/notification_event.dart';
import '../logic/blocs/notification/notification_state.dart';
import '../widgets/app_loading_indicator.dart';
import 'match_details_screen.dart';
import '../core/utils/sport_icon_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMatch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh notifications when mounting screen
    context.read<NotificationBloc>().add(const NotificationFetched());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationBloc>().add(const NotificationFetchedMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  IconData _getIconForType(String type, String? sportType) {
    if (type == 'match_joined') {
      switch (sportType?.toLowerCase()) {
        case 'football':
          return Icons.sports_soccer_rounded;
        case 'basketball':
          return Icons.sports_basketball_rounded;
        case 'tennis':
          return Icons.sports_tennis_rounded;
        case 'badminton':
          return Icons.sports_tennis;
        case 'cricket':
          return Icons.sports_cricket_rounded;
        default:
          return Icons.sports_rounded;
      }
    } else if (type == 'match_left') {
      return Icons.exit_to_app_rounded;
    }
    return Icons.notifications_rounded;
  }

  Color _getColorForType(BuildContext context, String type, String? sportType) {
    if (type == 'match_joined') {
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
          return Theme.of(context).colorScheme.primaryContainer;
      }
    } else if (type == 'match_left') {
      return Colors.redAccent;
    }
    return Theme.of(context).colorScheme.primaryContainer;
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read locally and on server
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(NotificationMarkedRead(notification.id));
    }

    final meta = notification.meta;
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final hasUnread = state.notifications.any((n) => !n.isRead);
                  if (!hasUnread) return const SizedBox.shrink();

                  return IconButton(
                    icon: Icon(Icons.done_all, color: Theme.of(context).colorScheme.primaryContainer),
                    tooltip: 'Mark all as read',
                    onPressed: () {
                      context.read<NotificationBloc>().add(const NotificationMarkAllRead());
                    },
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.status == NotificationStatus.initial ||
                  (state.status == NotificationStatus.loading && state.notifications.isEmpty)) {
                return const Center(child: AppLoadingIndicator());
              }

              if (state.status == NotificationStatus.failure && state.notifications.isEmpty) {
                return _buildErrorState(state.errorMessage ?? 'An error occurred');
              }

              if (state.notifications.isEmpty) {
                return _buildEmptyState();
              }

              // Group notifications
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));

              final todayNotifications = <NotificationModel>[];
              final yesterdayNotifications = <NotificationModel>[];
              final earlierNotifications = <NotificationModel>[];

              for (final n in state.notifications) {
                final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
                if (date.isAtSameMomentAs(today)) {
                  todayNotifications.add(n);
                } else if (date.isAtSameMomentAs(yesterday)) {
                  yesterdayNotifications.add(n);
                } else {
                  earlierNotifications.add(n);
                }
              }

              final listItems = <dynamic>[];
              if (todayNotifications.isNotEmpty) {
                listItems.add('Today');
                listItems.addAll(todayNotifications);
              }
              if (yesterdayNotifications.isNotEmpty) {
                listItems.add('Yesterday');
                listItems.addAll(yesterdayNotifications);
              }
              if (earlierNotifications.isNotEmpty) {
                listItems.add('Earlier');
                listItems.addAll(earlierNotifications);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(const NotificationFetched());
                },
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.hasMore ? listItems.length + 1 : listItems.length,
                  itemBuilder: (context, index) {
                    if (index >= listItems.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: AppLoadingIndicator(),
                        ),
                      );
                    }

                    final item = listItems[index];
                    if (item is String) {
                      return _buildNotificationGroup(context, item);
                    }

                    final notification = item as NotificationModel;
                    final meta = notification.meta;
                    final sportType = meta?['sport_type'] as String?;
                    final iconColor = _getColorForType(context, notification.type, sportType);

                    Widget? iconWidget;
                    IconData? iconData;
                    if (notification.type == 'match_joined') {
                      iconWidget = SportIconHelper.widgetForSport(
                        sportType ?? '',
                        size: 32,
                        color: iconColor,
                      );
                    } else {
                      iconData = _getIconForType(notification.type, sportType);
                    }

                    return GestureDetector(
                      onTap: () => _handleNotificationTap(notification),
                      child: _buildNotificationItem(
                        context,
                        iconWidget: iconWidget,
                        icon: iconData,
                        iconColor: iconColor,
                        title: notification.title,
                        message: notification.message,
                        time: _getRelativeTime(notification.createdAt),
                        isUnread: !notification.isRead,
                      ),
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

  Widget _buildNotificationGroup(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    Widget? iconWidget,
    IconData? icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnread 
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnread 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget != null
              ? SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: iconWidget),
                )
              : Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon!, color: iconColor, size: AppIconSize.sm),
                ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
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
                Icons.notifications_none_rounded,
                size: AppIconSize.hero,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Notifications Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You will get notified here when other players join or interact with your matches!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
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
              'Failed to load notifications',
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
                context.read<NotificationBloc>().add(const NotificationFetched());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
