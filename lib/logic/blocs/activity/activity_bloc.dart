import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/repositories/activity_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _activityRepository;

  ActivityBloc({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository,
        super(const ActivityState()) {
    on<ActivityFetched>(_onActivityFetched);
    on<ActivityFetchedMore>(_onActivityFetchedMore);
  }

  Future<void> _onActivityFetched(
    ActivityFetched event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(
      status: ActivityStatus.loading,
      clearError: true,
      clearNextPage: true,
      hasMore: false,
    ));

    try {
      final result = await _activityRepository.getActivities(page: 1);
      emit(state.copyWith(
        status: ActivityStatus.success,
        activities: result.activities,
        nextPage: result.nextPage,
        hasMore: result.nextPage != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ActivityStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onActivityFetchedMore(
    ActivityFetchedMore event,
    Emitter<ActivityState> emit,
  ) async {
    if (!state.hasMore || state.status == ActivityStatus.loadingMore) return;

    emit(state.copyWith(status: ActivityStatus.loadingMore));

    try {
      final nextPageNum = state.nextPage ?? 2;
      final result = await _activityRepository.getActivities(page: nextPageNum);
      emit(state.copyWith(
        status: ActivityStatus.success,
        activities: [...state.activities, ...result.activities],
        nextPage: result.nextPage,
        hasMore: result.nextPage != null,
      ));
    } catch (e) {
      // Keep existing data on failure, but clear loading status
      emit(state.copyWith(
        status: ActivityStatus.success,
      ));
    }
  }
}
