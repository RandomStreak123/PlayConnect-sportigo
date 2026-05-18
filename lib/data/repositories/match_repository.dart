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

  Future<List<MatchModel>> getNearbyMatches({String? sportType, String? skillLevel, String? search}) async {
    final token = await _getToken();
    
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

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.matches}').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MatchModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load matches');
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
      body: jsonEncode(match.toJson()),
    );

    if (response.statusCode == 201) {
      return MatchModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create match');
    }
  }

  Future<void> joinMatch(String matchId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.joinMatch(matchId)}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to join match');
    }
  }

  Future<void> leaveMatch(String matchId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.leaveMatch(matchId)}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to leave match');
    }
  }
}


