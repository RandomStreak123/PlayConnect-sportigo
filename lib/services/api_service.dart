import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {


  static const String baseUrl = ApiConstants.baseUrl;

  Future<List<Map<String, dynamic>>> fetchSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse("$baseUrl/slots"),
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final list = body['data'] as List;
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception("Failed to fetch slots");
    }
  }

  Future<void> updateSlot({
    required int slotId,
    required String newTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.put(
      Uri.parse("$baseUrl/slots/update"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "slot_id": slotId,
        "new_time": newTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update slot");
    }
  }
}
