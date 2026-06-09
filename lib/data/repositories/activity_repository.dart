import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../../core/constants/api_constants.dart';

class ActivityRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<({List<ActivityModel> activities, int? nextPage})> getActivities({int page = 1}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.activities}?page=$page'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>;
        final activities = data.map((json) => ActivityModel.fromJson(json)).toList();
        
        final nextPageUrl = body['next_page_url'];
        final nextPage = nextPageUrl != null ? page + 1 : null;

        return (activities: activities, nextPage: nextPage);
      } catch (e) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception('Failed to load activity feed');
    }
  }
}
