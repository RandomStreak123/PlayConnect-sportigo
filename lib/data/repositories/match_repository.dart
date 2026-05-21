import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';
import '../../core/constants/api_constants.dart';

class MatchRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, dynamic>? _decodeJsonBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    final data = _decodeJsonBody(response.body);
    if (data != null) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<List<MatchModel>> getMyMatches() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myMatches}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MatchModel.fromJson(json)).toList();
      } catch (_) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to load your matches'));
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
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

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

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.matches}').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = body['data'] as List<dynamic>;
        final String? nextCursor = body['next_cursor'] as String?;
        final matches = data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
        return (matches: matches, nextCursor: nextCursor);
      } catch (_) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to load matches'));
    }
  }

  Future<MatchModel> createMatch(MatchModel match) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.matches}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(match.toCreateJson()),
    );

    if (response.statusCode == 201) {
      try {
        return MatchModel.fromJson(jsonDecode(response.body));
      } catch (_) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to create match'));
    }
  }

  Future<MatchModel> joinMatch(String matchId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.joinMatch(matchId)}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final matchJson = data['match'];
        if (matchJson is Map<String, dynamic>) {
          return MatchModel.fromJson(matchJson);
        }
        throw Exception('Invalid server response');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to join match'));
    }
  }

  Future<MatchModel> leaveMatch(String matchId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveMatch(matchId)}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final matchJson = data['match'];
        if (matchJson is Map<String, dynamic>) {
          return MatchModel.fromJson(matchJson);
        }
        throw Exception('Invalid server response');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to leave match'));
    }
  }

  Future<MatchModel> getMatch(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.matches}/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        return MatchModel.fromJson(jsonDecode(response.body));
      } catch (_) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to load match details'));
    }
  }
}
