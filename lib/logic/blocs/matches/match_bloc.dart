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
    on<MatchFetchedMore>(_onMatchFetchedMore);
    on<MyMatchesFetched>(_onMyMatchesFetched);
    on<MatchJoined>(_onMatchJoined);
    on<MatchLeft>(_onMatchLeft);
    on<MatchCreated>(_onMatchCreated);
  }

  final MatchRepository _matchRepository;

  String? _lastSportType;
  String? _lastSkillLevel;
  String? _lastSearch;

  String? _normalizeFilter(String? value) {
    if (value == null || value.isEmpty || value == 'All') return null;
    return value;
  }

  String? _normalizeSkillLevel(String? value) {
    final normalized = _normalizeFilter(value);
    if (normalized == 'Pro') return 'Professional';
    return normalized;
  }

  List<MatchModel> _upsertMatch(List<MatchModel> list, MatchModel updated) {
    final index = list.indexWhere((m) => m.id == updated.id);
    if (index < 0) return list;
    final next = List<MatchModel>.from(list);
    next[index] = updated;
    return next;
  }

  List<MatchModel> _upsertOrAppendMyMatch(
    List<MatchModel> list,
    MatchModel updated,
  ) {
    final index = list.indexWhere((m) => m.id == updated.id);
    final next = List<MatchModel>.from(list);
    if (index >= 0) {
      next[index] = updated;
    } else {
      next.insert(0, updated);
    }
    return next;
  }

  /// Fetches a page of nearby matches. Pass [cursor] to load a subsequent page.
  Future<({List<MatchModel> matches, String? nextCursor})> _fetchNearbyMatches({
    String? cursor,
  }) {
    return _matchRepository.getNearbyMatches(
      sportType: _normalizeFilter(_lastSportType),
      skillLevel: _normalizeSkillLevel(_lastSkillLevel),
      search: _normalizeFilter(_lastSearch),
      cursor: cursor,
    );
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onMatchFetched(
    MatchFetched event,
    Emitter<MatchState> emit,
  ) async {
    _lastSportType = event.sportType;
    _lastSkillLevel = event.skillLevel;
    _lastSearch = event.search;

    emit(state.copyWith(
      status: MatchStatus.loading,
      clearMessage: true,
      clearCursor: true,
      hasMore: false,
    ));

    try {
      final result = await _fetchNearbyMatches();
      emit(state.copyWith(
        status: MatchStatus.success,
        matches: result.matches,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (_) {
      emit(state.copyWith(status: MatchStatus.failure));
    }
  }

  /// Appends the next page to the existing list when the user scrolls down.
  Future<void> _onMatchFetchedMore(
    MatchFetchedMore event,
    Emitter<MatchState> emit,
  ) async {
    // Guard: only load more if there is actually a next page and we are not
    // already loading.
    if (!state.hasMore || state.status == MatchStatus.loadingMore) return;

    emit(state.copyWith(status: MatchStatus.loadingMore));

    try {
      final result = await _fetchNearbyMatches(cursor: state.nextCursor);
      emit(state.copyWith(
        status: MatchStatus.success,
        matches: [...state.matches, ...result.matches],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (_) {
      // On failure keep the existing list and clear the loading indicator.
      emit(state.copyWith(status: MatchStatus.success));
    }
  }

  Future<void> _onMatchCreated(
    MatchCreated event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    try {
      await _matchRepository.createMatch(event.match);
      // Refresh from page 1 after creating so the new match appears correctly.
      final result = await _fetchNearbyMatches();
      final myMatches = await _matchRepository.getMyMatches();
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: result.matches,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        myMatches: myMatches,
        message: 'Match created successfully!',
        isActionSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.success,
        message: e.toString().replaceAll('Exception: ', ''),
        isActionSuccess: false,
      ));
    }
  }

  Future<void> _onMatchLeft(
    MatchLeft event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    try {
      final updated = await _matchRepository.leaveMatch(event.matchId);
      final matches = _upsertMatch(state.matches, updated);
      final myMatches = state.myMatches
          .where((m) => m.id != updated.id)
          .toList(growable: false);
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        myMatches: myMatches,
        message: 'Successfully left match',
        isActionSuccess: true,
      ));
    } catch (e) {
      try {
        final result = await _fetchNearbyMatches();
        final myMatches = await _matchRepository.getMyMatches();
        emit(state.copyWith(
          status: MatchStatus.success,
          myMatchesStatus: MatchStatus.success,
          matches: result.matches,
          nextCursor: result.nextCursor,
          hasMore: result.nextCursor != null,
          myMatches: myMatches,
          message: e.toString().replaceAll('Exception: ', ''),
          isActionSuccess: false,
        ));
      } catch (_) {
        emit(state.copyWith(
          status: MatchStatus.success,
          message: e.toString().replaceAll('Exception: ', ''),
          isActionSuccess: false,
        ));
      }
    }
  }

  Future<void> _onMatchJoined(
    MatchJoined event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    try {
      final updated = await _matchRepository.joinMatch(event.matchId);
      final matches = _upsertMatch(state.matches, updated);
      final myMatches = _upsertOrAppendMyMatch(state.myMatches, updated);
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        myMatches: myMatches,
        message: 'Successfully joined match!',
        isActionSuccess: true,
      ));
    } catch (e) {
      try {
        final result = await _fetchNearbyMatches();
        final myMatches = await _matchRepository.getMyMatches();
        emit(state.copyWith(
          status: MatchStatus.success,
          myMatchesStatus: MatchStatus.success,
          matches: result.matches,
          nextCursor: result.nextCursor,
          hasMore: result.nextCursor != null,
          myMatches: myMatches,
          message: e.toString().replaceAll('Exception: ', ''),
          isActionSuccess: false,
        ));
      } catch (_) {
        emit(state.copyWith(
          status: MatchStatus.success,
          message: e.toString().replaceAll('Exception: ', ''),
          isActionSuccess: false,
        ));
      }
    }
  }

  Future<void> _onMyMatchesFetched(
    MyMatchesFetched event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(myMatchesStatus: MatchStatus.loading, clearMessage: true));
    try {
      final myMatches = await _matchRepository.getMyMatches();
      emit(state.copyWith(
        myMatchesStatus: MatchStatus.success,
        myMatches: myMatches,
      ));
    } catch (_) {
      emit(state.copyWith(myMatchesStatus: MatchStatus.failure));
    }
  }
}
