import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../../core/constants/api_constants.dart';

class NotificationRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<({List<NotificationModel> notifications, String? nextCursor})> getNotifications({String? cursor}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final url = cursor != null 
        ? '${ApiConstants.baseUrl}/notifications?cursor=$cursor' 
        : '${ApiConstants.baseUrl}/notifications';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] as List<dynamic>;
        final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
        
        final String? nextCursor = body['next_cursor'] as String?;

        return (notifications: notifications, nextCursor: nextCursor);
      } catch (e) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return NotificationModel.fromJson(body['data']);
      } catch (e) {
        throw Exception('Invalid server response');
      }
    } else {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    final token = await _getToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }
}
