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

  Future<UserModel?> _getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('cached_user');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _removeLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  // ──────────────────────────────────────────────────────────
  // REAL AUTH METHODS
  // ──────────────────────────────────────────────────────────

  /// Register.
  Future<UserModel> register({
    required String name,
    required String username,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'password': password,
        'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      final token = data['access_token'];

      await _saveToken(token);
      await _saveUserLocally(user);
      _controller.add(AuthStatus.authenticated);
      return user;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Registration failed');
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
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      final token = data['access_token'];

      await _saveToken(token);
      await _saveUserLocally(user);
      _controller.add(AuthStatus.authenticated);
      return user;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Login failed');
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
    final localUser = await _getLocalUser();
    if (localUser != null) {
      return localUser;
    }
    
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
      final user = UserModel.fromJson(jsonDecode(response.body));
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
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      await _saveUserLocally(user);
      return user;
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Profile photo upload failed');
      } catch (_) {
        throw Exception('Profile photo upload failed: ${response.statusCode}');
      }
    }
  }

  void dispose() => _controller.close();
}


