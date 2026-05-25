import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "http://YOUR_IP:8000/api";

  Future<void> updateSlot({
    required int slotId,
    required String newTime,
  }) async {

    final response = await http.put(
      Uri.parse("$baseUrl/slots/update"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
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
