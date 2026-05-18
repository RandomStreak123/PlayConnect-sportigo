part of 'match_bloc.dart';

enum MatchStatus { initial, loading, success, failure, actionSuccess, actionFailure }

class MatchState {
  const MatchState({
    this.status = MatchStatus.initial,
    this.matches = const <MatchModel>[],
    this.message,
  });

  final MatchStatus status;
  final List<MatchModel> matches;
  final String? message;

  MatchState copyWith({
    MatchStatus? status,
    List<MatchModel>? matches,
    String? message,
    bool clearMessage = false,
  }) {
    return MatchState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
