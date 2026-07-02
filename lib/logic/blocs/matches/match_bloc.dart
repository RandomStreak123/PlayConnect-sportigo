import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/match_repository.dart';
import 'package:geolocator/geolocator.dart';

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
    on<MatchResultsRecorded>(_onMatchResultsRecorded);
    on<MatchRatingsSubmitted>(_onMatchRatingsSubmitted);
  }

  final MatchRepository _matchRepository;

  String? _lastSportType;
  String? _lastSkillLevel;
  String? _lastSearch;

  final Map<String, List<MatchModel>> _cache = {};
  final Map<String, String?> _cacheCursors = {};
  final Map<String, DateTime> _cacheTimestamps = {};

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

    final key = '${event.sportType ?? 'All'}_${event.skillLevel ?? 'All'}_${event.search ?? ''}';
    final isUnfiltered = (event.sportType == null || event.sportType == 'All') &&
        (event.skillLevel == null || event.skillLevel == 'All') &&
        (event.search == null || event.search!.isEmpty);

    // 1. Check if we have a valid cache that is recent (e.g., < 10 seconds old) and not forced
    if (!event.forceRefresh && _cache.containsKey(key)) {
      final lastFetch = _cacheTimestamps[key];
      if (lastFetch != null && DateTime.now().difference(lastFetch) < const Duration(seconds: 10)) {
        emit(state.copyWith(
          status: MatchStatus.success,
          matches: _cache[key],
          trendingMatches: isUnfiltered ? _cache[key] : state.trendingMatches,
          sportType: event.sportType,
          skillLevel: event.skillLevel,
          search: event.search,
          nextCursor: _cacheCursors[key],
          hasMore: _cacheCursors[key] != null,
          clearMessage: true,
        ));
        return;
      }
    }

    // 2. If we have cached results, emit them instantly as a baseline (success status to keep list rendering)
    if (_cache.containsKey(key)) {
      emit(state.copyWith(
        status: MatchStatus.success,
        matches: _cache[key],
        trendingMatches: isUnfiltered ? _cache[key] : state.trendingMatches,
        sportType: event.sportType,
        skillLevel: event.skillLevel,
        search: event.search,
        nextCursor: _cacheCursors[key],
        hasMore: _cacheCursors[key] != null,
        clearMessage: true,
      ));
    } else {
      // 3. Fallback: filter current matches in memory to show matching items instantly
      final currentMatches = state.matches;
      final localFiltered = currentMatches.where((m) {
        if (event.sportType != null && event.sportType != 'All' && m.sportType.toLowerCase() != event.sportType!.toLowerCase()) {
          return false;
        }
        if (event.skillLevel != null && event.skillLevel != 'All' && m.skillLevel.toLowerCase() != event.skillLevel!.toLowerCase()) {
          return false;
        }
        if (event.search != null && !m.title.toLowerCase().contains(event.search!.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

      emit(state.copyWith(
        status: MatchStatus.loading,
        matches: localFiltered,
        sportType: event.sportType,
        skillLevel: event.skillLevel,
        search: event.search,
        clearMessage: true,
        clearCursor: true,
        hasMore: false,
      ));
    }

    // 4. Fetch the fresh data in the background
    try {
      final result = await _fetchNearbyMatches();
      final matchesWithDistance = await _calculateDistances(result.matches);
      
      // Update cache
      _cache[key] = matchesWithDistance;
      _cacheCursors[key] = result.nextCursor;
      _cacheTimestamps[key] = DateTime.now();

      // Only emit the results if the filters haven't changed while we were fetching
      if (_lastSportType == event.sportType &&
          _lastSkillLevel == event.skillLevel &&
          _lastSearch == event.search) {
        emit(state.copyWith(
          status: MatchStatus.success,
          matches: matchesWithDistance,
          trendingMatches: isUnfiltered ? matchesWithDistance : state.trendingMatches,
          sportType: event.sportType,
          skillLevel: event.skillLevel,
          search: event.search,
          nextCursor: result.nextCursor,
          hasMore: result.nextCursor != null,
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('MATCH_FETCH_ERROR: $e');
      debugPrint(stackTrace.toString());
      // If we already have cached/local matches, don't show failure screen, just keep what we have
      if (_cache.containsKey(key) || state.matches.isNotEmpty) {
        emit(state.copyWith(status: MatchStatus.success));
      } else {
        emit(state.copyWith(status: MatchStatus.failure));
      }
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
      final key = '${_lastSportType ?? 'All'}_${_lastSkillLevel ?? 'All'}_${_lastSearch ?? ''}';
      final isUnfiltered = (_lastSportType == null || _lastSportType == 'All') &&
          (_lastSkillLevel == null || _lastSkillLevel == 'All') &&
          (_lastSearch == null || _lastSearch!.isEmpty);
      
      final matchesWithDistance = await _calculateDistances(result.matches);
      final updatedMatches = [...state.matches, ...matchesWithDistance];

      // Update cache for this key so it includes the appended page
      _cache[key] = updatedMatches;
      _cacheCursors[key] = result.nextCursor;
      _cacheTimestamps[key] = DateTime.now();

      emit(state.copyWith(
        status: MatchStatus.success,
        matches: updatedMatches,
        trendingMatches: isUnfiltered ? updatedMatches : state.trendingMatches,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      ));
    } catch (e, stackTrace) {
      debugPrint('MATCH_FETCH_MORE_ERROR: $e');
      debugPrint(stackTrace.toString());
      // On failure keep the existing list and clear the loading indicator.
      emit(state.copyWith(status: MatchStatus.success));
    }
  }

  Future<List<MatchModel>> _calculateDistances(List<MatchModel> matches) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return matches;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return matches;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
          forceAndroidLocationManager: true,
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return matches;
      }

      final double userLat = position.latitude;
      final double userLng = position.longitude;

      return matches.map((match) {
        if (match.latitude != null && match.longitude != null) {
          final double distanceInMeters = Geolocator.distanceBetween(
            userLat,
            userLng,
            match.latitude!,
            match.longitude!,
          );
          return match.copyWith(distance: distanceInMeters / 1000.0);
        }
        return match;
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('CALCULATE_DISTANCES_ERROR: Failed to calculate distances: $e');
      debugPrint(stackTrace.toString());
      return matches;
    }
  }

  Future<void> _onMatchCreated(
    MatchCreated event,
    Emitter<MatchState> emit,
  ) async {
    _cache.clear();
    _cacheCursors.clear();
    _cacheTimestamps.clear();
    emit(state.copyWith(clearMessage: true));
    try {
      final newMatch = await _matchRepository.createMatch(event.match);
      
      final isUnfiltered = (_lastSportType == null || _lastSportType == 'All') &&
          (_lastSkillLevel == null || _lastSkillLevel == 'All') &&
          (_lastSearch == null || _lastSearch!.isEmpty);

      final matches = [newMatch, ...state.matches];
      final trendingMatches = isUnfiltered ? [newMatch, ...state.trendingMatches] : state.trendingMatches;
      final myMatches = [newMatch, ...state.myMatches];

      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        trendingMatches: trendingMatches,
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
    final matchId = event.matchId;
    MatchModel? match;
    try {
      match = state.matches.firstWhere((m) => m.id == matchId);
    } catch (_) {
      try {
        match = state.trendingMatches.firstWhere((m) => m.id == matchId);
      } catch (_) {
        try {
          match = state.myMatches.firstWhere((m) => m.id == matchId);
        } catch (_) {
          // Skip optimistic
        }
      }
    }

    final originalMatches = state.matches;
    final originalTrending = state.trendingMatches;
    final originalMyMatches = state.myMatches;

    _cache.clear();
    _cacheCursors.clear();
    _cacheTimestamps.clear();
    emit(state.copyWith(clearMessage: true));

    if (match != null) {
      final updatedParticipants = match.participants
          .where((p) => p.id != event.userId)
          .toList();

      final optimisticMatch = match.copyWith(
        participants: updatedParticipants,
        availableSlots: match.availableSlots + 1,
        joinedCount: math.max(0, match.joinedCount - 1),
      );

      final matches = _upsertMatch(state.matches, optimisticMatch);
      final trending = _upsertMatch(state.trendingMatches, optimisticMatch);
      final myMatches = state.myMatches
          .where((m) => m.id != optimisticMatch.id)
          .toList(growable: false);

      emit(state.copyWith(
        matches: matches,
        trendingMatches: trending,
        myMatches: myMatches,
      ));
    }

    try {
      final updated = await _matchRepository.leaveMatch(matchId);
      final matches = _upsertMatch(state.matches, updated);
      final trending = _upsertMatch(state.trendingMatches, updated);
      final myMatches = state.myMatches
          .where((m) => m.id != updated.id)
          .toList(growable: false);
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        trendingMatches: trending,
        myMatches: myMatches,
        message: 'Successfully left match',
        isActionSuccess: true,
      ));
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: originalMatches,
        trendingMatches: originalTrending,
        myMatches: originalMyMatches,
        message: e.toString().replaceAll('Exception: ', ''),
        isActionSuccess: false,
      ));
    }
  }

  Future<void> _onMatchJoined(
    MatchJoined event,
    Emitter<MatchState> emit,
  ) async {
    final matchId = event.matchId;
    MatchModel? match;
    try {
      match = state.matches.firstWhere((m) => m.id == matchId);
    } catch (_) {
      try {
        match = state.trendingMatches.firstWhere((m) => m.id == matchId);
      } catch (_) {
        try {
          match = state.myMatches.firstWhere((m) => m.id == matchId);
        } catch (_) {
          // Skip optimistic
        }
      }
    }

    final originalMatches = state.matches;
    final originalTrending = state.trendingMatches;
    final originalMyMatches = state.myMatches;

    _cache.clear();
    _cacheCursors.clear();
    _cacheTimestamps.clear();
    emit(state.copyWith(clearMessage: true));

    if (match != null) {
      final isAlreadyJoined = match.participants.any((p) => p.id == event.user.id);
      if (!isAlreadyJoined) {
        final updatedParticipants = List<MatchParticipant>.from(match.participants)
          ..add(MatchParticipant(
            id: event.user.id,
            name: event.user.name,
            profilePicture: event.user.profilePicture,
          ));

        final optimisticMatch = match.copyWith(
          participants: updatedParticipants,
          availableSlots: math.max(0, match.availableSlots - 1),
          joinedCount: match.joinedCount + 1,
        );

        final matches = _upsertMatch(state.matches, optimisticMatch);
        final trending = _upsertMatch(state.trendingMatches, optimisticMatch);
        final myMatches = _upsertOrAppendMyMatch(state.myMatches, optimisticMatch);

        emit(state.copyWith(
          matches: matches,
          trendingMatches: trending,
          myMatches: myMatches,
        ));
      }
    }

    try {
      final updated = await _matchRepository.joinMatch(matchId);
      final matches = _upsertMatch(state.matches, updated);
      final trending = _upsertMatch(state.trendingMatches, updated);
      final myMatches = _upsertOrAppendMyMatch(state.myMatches, updated);
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        trendingMatches: trending,
        myMatches: myMatches,
        message: 'Successfully joined match!',
        isActionSuccess: true,
      ));
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: originalMatches,
        trendingMatches: originalTrending,
        myMatches: originalMyMatches,
        message: e.toString().replaceAll('Exception: ', ''),
        isActionSuccess: false,
      ));
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

  Future<void> _onMatchResultsRecorded(
    MatchResultsRecorded event,
    Emitter<MatchState> emit,
  ) async {
    _cache.clear();
    _cacheCursors.clear();
    _cacheTimestamps.clear();
    emit(state.copyWith(clearMessage: true));
    try {
      final updated = await _matchRepository.recordResults(event.matchId, event.results);
      final matches = _upsertMatch(state.matches, updated);
      final trending = _upsertMatch(state.trendingMatches, updated);
      final myMatches = _upsertMatch(state.myMatches, updated);
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        trendingMatches: trending,
        myMatches: myMatches,
        message: 'Match results recorded successfully!',
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

  Future<void> _onMatchRatingsSubmitted(
    MatchRatingsSubmitted event,
    Emitter<MatchState> emit,
  ) async {
    _cache.clear();
    _cacheCursors.clear();
    _cacheTimestamps.clear();
    emit(state.copyWith(clearMessage: true));
    try {
      await _matchRepository.submitRatings(event.matchId, event.ratings);
      final updated = await _matchRepository.getMatch(event.matchId);
      final matches = _upsertMatch(state.matches, updated);
      final trending = _upsertMatch(state.trendingMatches, updated);
      final myMatches = _upsertMatch(state.myMatches, updated);
      
      emit(state.copyWith(
        status: MatchStatus.success,
        myMatchesStatus: MatchStatus.success,
        matches: matches,
        trendingMatches: trending,
        myMatches: myMatches,
        message: 'Ratings submitted successfully!',
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
}
