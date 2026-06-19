import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({
    required NotificationRepository notificationRepository,
  })  : _notificationRepository = notificationRepository,
        super(const NotificationState()) {
    on<NotificationFetched>(_onFetched);
    on<NotificationFetchedMore>(_onFetchedMore);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
  }

  Future<void> _onFetched(
    NotificationFetched event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final result = await _notificationRepository.getNotifications();
      
      // Preserve local read status for any notifications that were already marked read locally
      final mergedNotifications = result.notifications.map((newNotification) {
        final localNotification = state.notifications.firstWhere(
          (n) => n.id == newNotification.id,
          orElse: () => newNotification,
        );
        if (localNotification.isRead) {
          return newNotification.copyWith(isRead: true);
        }
        return newNotification;
      }).toList();

      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: mergedNotifications,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onFetchedMore(
    NotificationFetchedMore event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.status == NotificationStatus.loadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    emit(state.copyWith(status: NotificationStatus.loadingMore));
    try {
      final result = await _notificationRepository.getNotifications(cursor: state.nextCursor);
      
      // Preserve local read status for any fetched-more notifications
      final mergedFetchedNotifications = result.notifications.map((newNotification) {
        final localNotification = state.notifications.firstWhere(
          (n) => n.id == newNotification.id,
          orElse: () => newNotification,
        );
        if (localNotification.isRead) {
          return newNotification.copyWith(isRead: true);
        }
        return newNotification;
      }).toList();

      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: List.of(state.notifications)..addAll(mergedFetchedNotifications),
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic UI update
    final updatedNotifications = state.notifications.map((n) {
      return n.id == event.id ? n.copyWith(isRead: true) : n;
    }).toList();
    emit(state.copyWith(notifications: updatedNotifications));

    try {
      await _notificationRepository.markAsRead(event.id);
    } catch (_) {
      // Revert optimistic update if request failed
      final revertedNotifications = state.notifications.map((n) {
        return n.id == event.id ? n.copyWith(isRead: false) : n;
      }).toList();
      emit(state.copyWith(notifications: revertedNotifications));
    }
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final previousNotifications = state.notifications;

    // Optimistic UI update
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    emit(state.copyWith(notifications: updatedNotifications));

    try {
      await _notificationRepository.markAllAsRead();
    } catch (_) {
      // Revert to previous state if request failed
      emit(state.copyWith(notifications: previousNotifications));
    }
  }
}
