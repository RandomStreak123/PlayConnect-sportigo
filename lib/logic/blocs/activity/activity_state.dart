part of 'activity_bloc.dart';

enum ActivityStatus { initial, loading, success, failure, loadingMore }

class ActivityState {
  final ActivityStatus status;
  final List<ActivityModel> activities;
  final int? nextPage;
  final bool hasMore;
  final String? errorMessage;

  const ActivityState({
    this.status = ActivityStatus.initial,
    this.activities = const [],
    this.nextPage,
    this.hasMore = false,
    this.errorMessage,
  });

  ActivityState copyWith({
    ActivityStatus? status,
    List<ActivityModel>? activities,
    int? nextPage,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    bool clearNextPage = false,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      nextPage: clearNextPage ? null : (nextPage ?? this.nextPage),
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
