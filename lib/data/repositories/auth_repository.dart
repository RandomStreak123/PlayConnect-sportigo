import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final _controller = StreamController<AuthStatus>();

  AuthRepository();

  Stream<AuthStatus> get status async* {
    final token = await _getToken();
    if (token != null) {
      yield AuthStatus.authenticated;
    } else {
      yield AuthStatus.unauthenticated;
    }
    yield* _controller.stream;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  Future<void> _removeLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
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

  /// Register.
  Future<UserModel> register({
    required String name,
    required String username,
    required String password,
    String? phoneNumber,
    String? gender,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
        'phone_number': phoneNumber,
        'gender': gender,
      }),
    );

    if (response.statusCode == 201) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final user = UserModel.fromJson(data['user']);
      final token = data['access_token'];

      await _saveToken(token);
      await _saveUserLocally(user);
      _controller.add(AuthStatus.authenticated);
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Registration failed'));
    }
  }

  /// Login.
  Future<UserModel> logIn({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final user = UserModel.fromJson(data['user']);
      final token = data['access_token'];

      await _saveToken(token);
      await _saveUserLocally(user);
      _controller.add(AuthStatus.authenticated);
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Login failed'));
    }
  }

  Future<void> logOut() async {
    final token = await _getToken();
    if (token != null) {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    await _removeToken();
    await _removeLocalUser();
    _controller.add(AuthStatus.unauthenticated);
  }

  /// Get user — returns local cache or fetches from server.
  Future<UserModel?> getUser() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.user}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) {
        await logOut();
        return null;
      }
      final user = UserModel.fromJson(data);
      await _saveUserLocally(user);
      return user;
    } else {
      await logOut();
      return null;
    }
  }

  Future<UserModel> uploadProfilePhoto(String filePath) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final uri = Uri.parse('${ApiConstants.baseUrl}/profile/photo');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(
      await http.MultipartFile.fromPath('profile_photo', filePath),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final user = UserModel.fromJson(data['user']);
      await _saveUserLocally(user);
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Profile photo upload failed'));
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phoneNumber,
    bool? hidePhone,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': ?name,
        'phone_number': ?phoneNumber,
        'hide_phone': ?hidePhone,
      }),
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final user = UserModel.fromJson(data['user']);
      await _saveUserLocally(user);
      return user;
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to update profile'));
    }
  }

  void dispose() => _controller.close();
}
