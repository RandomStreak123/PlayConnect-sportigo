import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/repositories/match_repository.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  MatchBloc({required MatchRepository matchRepository})
      : _matchRepository = matchRepository,
        super(const MatchState()) {
    on<MatchFetched>(_onMatchFetched);
    on<MatchJoined>(_onMatchJoined);
    on<MatchCreated>(_onMatchCreated);
  }

  final MatchRepository _matchRepository;

  Future<void> _onMatchCreated(
    MatchCreated event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    try {
      await _matchRepository.createMatch(event.match);
      // Refresh after creation
      final matches = await _matchRepository.getNearbyMatches();
      emit(state.copyWith(
        status: MatchStatus.actionSuccess,
        matches: matches,
        message: 'Match created successfully!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.actionFailure,
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onMatchJoined(
    MatchJoined event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    try {
      await _matchRepository.joinMatch(event.matchId);
      
      // Refresh matches after joining to get updated counts and participants
      final matches = await _matchRepository.getNearbyMatches();
      emit(state.copyWith(
        status: MatchStatus.actionSuccess,
        matches: matches,
        message: 'Successfully joined match!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.actionFailure,
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onMatchFetched(
    MatchFetched event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(status: MatchStatus.loading, clearMessage: true));
    try {
      final matches = await _matchRepository.getNearbyMatches(
        sportType: event.sportType == 'All' ? null : event.sportType,
      );
      emit(state.copyWith(
        status: MatchStatus.success,
        matches: matches,
      ));
    } catch (_) {
      emit(state.copyWith(status: MatchStatus.failure));
    }
  }
}
