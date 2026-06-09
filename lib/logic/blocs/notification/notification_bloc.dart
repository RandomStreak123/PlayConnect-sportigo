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
      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: result.notifications,
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
      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: List.of(state.notifications)..addAll(result.notifications),
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
      // Revert if request failed? Let's keep it read for UI simplicity.
    }
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic UI update
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    emit(state.copyWith(notifications: updatedNotifications));

    try {
      await _notificationRepository.markAllAsRead();
    } catch (_) {
      // Revert or ignore
    }
  }
}
