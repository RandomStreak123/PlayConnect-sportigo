import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final _controller = StreamController<AuthStatus>.broadcast();
  final _userController = StreamController<UserModel>.broadcast();

  AuthRepository();

  Stream<UserModel> get userUpdates => _userController.stream;

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final user = UserModel.fromJson(data['user']);
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
      try {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Ignore network errors to allow local logout to succeed
      }
    }

    await _removeToken();
    await _removeLocalUser();
    _controller.add(AuthStatus.unauthenticated);
  }

  Future<UserModel?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_user');
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        if (data is Map<String, dynamic>) {
          return UserModel.fromJson(data);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _refreshUserInBackground(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.user}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = _decodeJsonBody(response.body);
        if (data != null) {
          final user = UserModel.fromJson(data);
          await _saveUserLocally(user);
          _userController.add(user);
        }
      } else if (response.statusCode == 401) {
        await logOut();
      }
    } catch (_) {}
  }

  Future<UserModel?> _fetchUserFromServer(String token) async {
    try {
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
    } catch (_) {
      return null;
    }
  }

  /// Get user — returns local cache or fetches from server.
  Future<UserModel?> getUser({bool forceRefresh = false}) async {
    final token = await _getToken();
    if (token == null) return null;

    if (!forceRefresh) {
      final cachedUser = await _getCachedUser();
      if (cachedUser != null) {
        _refreshUserInBackground(token);
        return cachedUser;
      }
    }

    return _fetchUserFromServer(token);
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
    String? themePreference,
    String? bio,
    String? email,
    String? primarySport,
    String? skillTier,
    String? gender,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (hidePhone != null) body['hide_phone'] = hidePhone;
    if (themePreference != null) body['theme_preference'] = themePreference;
    if (bio != null) body['bio'] = bio;
    if (email != null) body['email'] = email;
    if (primarySport != null) body['primary_sport'] = primarySport;
    if (skillTier != null) body['skill_tier'] = skillTier;
    if (gender != null) body['gender'] = gender;

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
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

  Future<List<UserModel>> getPlayers({String? search}) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final queryParams = search != null && search.isNotEmpty ? {'search': search} : null;
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.players}').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      final List<dynamic> playersJson = data['data'];
      return playersJson.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to fetch players'));
    }
  }

  Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonBody(response.body);
      if (data == null) throw Exception('Invalid server response');
      return data;
    } else {
      throw Exception(_extractErrorMessage(response, 'Failed to fetch user profile'));
    }
  }

  Future<void> waveUser(int userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/wave'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response, 'Failed to send wave'));
    }
  }

  void dispose() {
    _controller.close();
    _userController.close();
  }
}
