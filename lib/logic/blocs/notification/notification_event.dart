abstract class NotificationEvent {
  const NotificationEvent();
}

class NotificationFetched extends NotificationEvent {
  const NotificationFetched();
}

class NotificationFetchedMore extends NotificationEvent {
  const NotificationFetchedMore();
}

class NotificationMarkedRead extends NotificationEvent {
  final String id;
  const NotificationMarkedRead(this.id);
}

class NotificationMarkAllRead extends NotificationEvent {
  const NotificationMarkAllRead();
}
