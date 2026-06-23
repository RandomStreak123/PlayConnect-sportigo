import '../../services/api_client.dart';
import '../models/match_model.dart';
import '../../core/constants/api_constants.dart';

class MatchRepository {
  final ApiClient apiClient;

  MatchRepository({required this.apiClient});

  Future<List<MatchModel>> getMyMatches() async {
    try {
      final List<dynamic> data = await apiClient.get(ApiConstants.myMatches) as List<dynamic>;
      return data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load your matches');
    }
  }

  /// Returns a record of (matches, nextCursor).
  /// Pass [cursor] from the previous call to load the next page.
  /// [cursor] == null means "load the first page".
  Future<({List<MatchModel> matches, String? nextCursor})> getNearbyMatches({
    String? sportType,
    String? skillLevel,
    String? search,
    String? cursor,
  }) async {
    final Map<String, String> queryParams = {};
    if (sportType != null && sportType.isNotEmpty) {
      queryParams['sport_type'] = sportType;
    }
    if (skillLevel != null && skillLevel.isNotEmpty) {
      queryParams['skill_level'] = skillLevel;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    try {
      final body = await apiClient.get(ApiConstants.matches, queryParams: queryParams) as Map<String, dynamic>;
      final List<dynamic> data = body['data'] as List<dynamic>;
      final String? nextCursor = body['next_cursor'] as String?;
      final matches = data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
      return (matches: matches, nextCursor: nextCursor);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load matches');
    }
  }

  Future<MatchModel> createMatch(MatchModel match) async {
    try {
      final body = await apiClient.post(ApiConstants.matches, body: match.toCreateJson());
      return MatchModel.fromJson(body as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to create match');
    }
  }

  Future<MatchModel> joinMatch(String matchId) async {
    try {
      final data = await apiClient.post(ApiConstants.joinMatch(matchId)) as Map<String, dynamic>;
      final matchJson = data['match'];
      if (matchJson is Map<String, dynamic>) {
        return MatchModel.fromJson(matchJson);
      }
      throw Exception('Invalid server response');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to join match');
    }
  }

  Future<MatchModel> leaveMatch(String matchId) async {
    try {
      final data = await apiClient.post(ApiConstants.leaveMatch(matchId)) as Map<String, dynamic>;
      final matchJson = data['match'];
      if (matchJson is Map<String, dynamic>) {
        return MatchModel.fromJson(matchJson);
      }
      throw Exception('Invalid server response');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to leave match');
    }
  }

  Future<MatchModel> getMatch(String id) async {
    try {
      final body = await apiClient.get('${ApiConstants.matches}/$id');
      return MatchModel.fromJson(body as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load match details');
    }
  }

  Future<MatchModel> recordResults(String matchId, List<Map<String, dynamic>> results) async {
    try {
      final data = await apiClient.post('/matches/$matchId/result', body: {'results': results}) as Map<String, dynamic>;
      final matchJson = data['match'];
      if (matchJson is Map<String, dynamic>) {
        return MatchModel.fromJson(matchJson);
      }
      throw Exception('Invalid server response');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to record results');
    }
  }

  Future<void> submitRatings(String matchId, List<Map<String, dynamic>> ratings) async {
    try {
      await apiClient.post('/matches/$matchId/ratings', body: {'ratings': ratings});
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to submit ratings');
    }
  }

  Future<List<dynamic>> getRatings(String matchId) async {
    try {
      return await apiClient.get('/matches/$matchId/ratings') as List<dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to load ratings');
    }
  }
}
