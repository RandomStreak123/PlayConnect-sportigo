import '../../../data/models/notification_model.dart';

enum NotificationStatus { initial, loading, loadingMore, success, failure }

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const <NotificationModel>[],
    this.nextCursor,
    this.hasMore = false,
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final String? nextCursor;
  final bool hasMore;
  final String? errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    String? nextCursor,
    bool? hasMore,
    String? errorMessage,
    bool clearCursor = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
