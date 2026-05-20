part of 'match_bloc.dart';

sealed class MatchEvent {
  const MatchEvent();
}

final class MatchFetched extends MatchEvent {
  const MatchFetched({
    this.sportType,
    this.skillLevel,
    this.search,
  });

  final String? sportType;
  final String? skillLevel;
  final String? search;
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
  const MatchJoined(this.matchId);
  final String matchId;
}

final class MatchLeft extends MatchEvent {
  const MatchLeft(this.matchId);
  final String matchId;
}

final class MatchCreated extends MatchEvent {
  const MatchCreated(this.match);
  final MatchModel match;
}
