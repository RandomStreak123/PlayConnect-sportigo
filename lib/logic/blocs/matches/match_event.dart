part of 'match_bloc.dart';

sealed class MatchEvent {
  const MatchEvent();
}

final class MatchFetched extends MatchEvent {
  const MatchFetched({
    this.sportType,
    this.skillLevel,
    this.search,
    this.forceRefresh = false,
  });

  final String? sportType;
  final String? skillLevel;
  final String? search;
  final bool forceRefresh;
}

/// Fired by the UI when the user scrolls near the end of the list.
/// Appends the next page to the existing [MatchState.matches].
final class MatchFetchedMore extends MatchEvent {
  const MatchFetchedMore();
}

final class MyMatchesFetched extends MatchEvent {
  const MyMatchesFetched();
}

final class MatchJoined extends MatchEvent {
  const MatchJoined({required this.matchId, required this.user});
  final String matchId;
  final UserModel user;
}

final class MatchLeft extends MatchEvent {
  const MatchLeft({required this.matchId, required this.userId});
  final String matchId;
  final int userId;
}

final class MatchCreated extends MatchEvent {
  const MatchCreated(this.match);
  final MatchModel match;
}

final class MatchResultsRecorded extends MatchEvent {
  const MatchResultsRecorded({required this.matchId, required this.results});
  final String matchId;
  final List<Map<String, dynamic>> results;
}

final class MatchRatingsSubmitted extends MatchEvent {
  const MatchRatingsSubmitted({required this.matchId, required this.ratings});
  final String matchId;
  final List<Map<String, dynamic>> ratings;
}
