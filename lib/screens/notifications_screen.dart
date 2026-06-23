import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/match_repository.dart';
import '../logic/blocs/notification/notification_bloc.dart';
import '../logic/blocs/notification/notification_event.dart';
import '../logic/blocs/notification/notification_state.dart';
import '../widgets/app_loading_indicator.dart';
import 'match_details_screen.dart';
import 'profile_screen.dart';
import 'notifications/widgets/notification_card.dart';
import 'notifications/widgets/notification_empty_state.dart';
import 'notifications/widgets/notification_error_state.dart';

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

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read locally and on server
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(NotificationMarkedRead(notification.id));
    }

    final meta = notification.meta;
    if (meta == null) return;

    if (notification.type == 'social') {
      final senderIdStr = meta['sender_id']?.toString();
      final senderId = senderIdStr != null ? int.tryParse(senderIdStr) : null;
      final senderName = meta['sender_name'] as String?;
      
      if (senderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              isCurrentUser: false,
              userId: senderId,
              playerName: senderName,
            ),
          ),
        );
      }
      return;
    }

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
                return NotificationErrorState(
                  message: state.errorMessage ?? 'An error occurred',
                  onRetry: () {
                    context.read<NotificationBloc>().add(const NotificationFetched());
                  },
                );
              }

              if (state.notifications.isEmpty) {
                return const NotificationEmptyState();
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

                    return NotificationCard(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
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
}
