import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;
  bool _hasCheckedStorage = false;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void setToken(String? token) {
    _token = token;
    _hasCheckedStorage = true;
  }

  Future<String?> _getOrLoadToken() async {
    if (_token != null) return _token;
    if (_hasCheckedStorage) return null;

    final prefs = await SharedPreferences.getInstance();
    final oldToken = prefs.getString('auth_token');
    const secureStorage = FlutterSecureStorage();
    if (oldToken != null && oldToken.isNotEmpty) {
      try {
        await secureStorage.write(key: 'auth_token', value: oldToken);
        await prefs.remove('auth_token');
      } catch (_) {}
      _token = oldToken;
      _hasCheckedStorage = true;
      return _token;
    }
    try {
      _token = await secureStorage.read(key: 'auth_token');
    } catch (_) {}
    _hasCheckedStorage = true;
    return _token;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getOrLoadToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final response = await _client.get(
      uri,
      headers: await _headers(),
    );
    return _handleResponse(response, 'Failed request GET $path');
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'Failed request POST $path');
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'Failed request PUT $path');
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response, 'Failed request DELETE $path');
  }

  Future<dynamic> postMultipart(String path, {required Map<String, String> files, Map<String, String>? fields}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    
    final token = await _getOrLoadToken();
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    if (fields != null) {
      request.fields.addAll(fields);
    }

    for (final entry in files.entries) {
      request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, 'Failed request POST Multipart $path');
  }

  dynamic _handleResponse(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    final message = _extractErrorMessage(response, fallback);
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}
