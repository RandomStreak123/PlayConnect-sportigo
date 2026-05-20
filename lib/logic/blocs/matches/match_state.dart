part of 'match_bloc.dart';

enum MatchStatus { initial, loading, loadingMore, success, failure }

class MatchState {
  const MatchState({
    this.status = MatchStatus.initial,
    this.myMatchesStatus = MatchStatus.initial,
    this.matches = const <MatchModel>[],
    this.myMatches = const <MatchModel>[],
    this.message,
    this.isActionSuccess = false,
    this.nextCursor,
    this.hasMore = false,
  });

  final MatchStatus status;
  final MatchStatus myMatchesStatus;
  final List<MatchModel> matches;
  final List<MatchModel> myMatches;
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
      message: clearMessage ? null : (message ?? this.message),
      isActionSuccess: isActionSuccess ?? this.isActionSuccess,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
