part of 'match_bloc.dart';

enum MatchStatus { initial, loading, loadingMore, success, failure }

class MatchState {
  const MatchState({
    this.status = MatchStatus.initial,
    this.myMatchesStatus = MatchStatus.initial,
    this.matches = const <MatchModel>[],
    this.myMatches = const <MatchModel>[],
    this.trendingMatches = const <MatchModel>[],
    this.sportType,
    this.skillLevel,
    this.search,
    this.message,
    this.isActionSuccess = false,
    this.nextCursor,
    this.hasMore = false,
  });

  final MatchStatus status;
  final MatchStatus myMatchesStatus;
  final List<MatchModel> matches;
  final List<MatchModel> myMatches;
  final List<MatchModel> trendingMatches;
  final String? sportType;
  final String? skillLevel;
  final String? search;
  final String? message;
  final bool isActionSuccess;

  /// Cursor token returned by the backend for the next page.
  final String? nextCursor;

  /// True when the backend indicates there are more pages.
  final bool hasMore;

  MatchState copyWith({
    MatchStatus? status,
    MatchStatus? myMatchesStatus,
    List<MatchModel>? matches,
    List<MatchModel>? myMatches,
    List<MatchModel>? trendingMatches,
    String? sportType,
    String? skillLevel,
    String? search,
    String? message,
    bool? isActionSuccess,
    bool clearMessage = false,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
  }) {
    return MatchState(
      status: status ?? this.status,
      myMatchesStatus: myMatchesStatus ?? this.myMatchesStatus,
      matches: matches ?? this.matches,
      myMatches: myMatches ?? this.myMatches,
      trendingMatches: trendingMatches ?? this.trendingMatches,
      sportType: sportType ?? this.sportType,
      skillLevel: skillLevel ?? this.skillLevel,
      search: search ?? this.search,
      message: clearMessage ? null : (message ?? this.message),
      isActionSuccess: isActionSuccess ?? this.isActionSuccess,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
