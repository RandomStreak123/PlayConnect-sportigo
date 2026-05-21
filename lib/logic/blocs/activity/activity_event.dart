part of 'activity_bloc.dart';

abstract class ActivityEvent {
  const ActivityEvent();
}

class ActivityFetched extends ActivityEvent {
  const ActivityFetched();
}

class ActivityFetchedMore extends ActivityEvent {
  const ActivityFetchedMore();
}
