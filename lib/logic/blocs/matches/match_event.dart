part of 'match_bloc.dart';

sealed class MatchEvent {
  const MatchEvent();
}

final class MatchFetched extends MatchEvent {
  const MatchFetched({this.sportType});
  final String? sportType;
}

final class MatchJoined extends MatchEvent {
  const MatchJoined(this.matchId);
  final String matchId;
}

final class MatchCreated extends MatchEvent {
  const MatchCreated(this.match);
  final MatchModel match;
}
