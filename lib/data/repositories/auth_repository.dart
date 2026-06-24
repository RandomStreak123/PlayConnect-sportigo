import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../../core/constants/api_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final ApiClient apiClient;
  final _controller = StreamController<AuthStatus>.broadcast();
  final _userController = StreamController<UserModel>.broadcast();

  AuthRepository({required this.apiClient});

  Stream<UserModel> get userUpdates => _userController.stream;

  Stream<AuthStatus> get status async* {
    final token = await _getToken();
    if (token != null) {
      apiClient.setToken(token);
      yield AuthStatus.authenticated;
    } else {
      apiClient.setToken(null);
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
    apiClient.setToken(token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    apiClient.setToken(null);
  }

  Future<void> _saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  Future<void> _removeLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  /// Register.
  Future<UserModel> register({
    required String name,
    required String username,
    required String password,
    String? phoneNumber,
    String? gender,
  }) async {
    try {
      final data = await apiClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'username': username,
          'password': password,
          'phone_number': phoneNumber,
          'gender': gender,
        },
      ) as Map<String, dynamic>;

      final user = UserModel.fromJson(data['user']);
      return user;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Registration failed');
    }
  }

  /// Login.
  Future<UserModel> logIn({
    required String username,
    required String password,
  }) async {
    try {
      final data = await apiClient.post(
        ApiConstants.login,
        body: {
          'username': username,
          'password': password,
        },
      ) as Map<String, dynamic>;

      final user = UserModel.fromJson(data['user']);
      final token = data['access_token'];

      await _saveToken(token);
      await _saveUserLocally(user);
      _controller.add(AuthStatus.authenticated);
      return user;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Login failed');
    }
  }

  Future<String> sendResetLink({
    required String username,
    required String email,
  }) async {
    try {
      final data = await apiClient.post(
        '/forgot-password',
        body: {
          'username': username,
          'email': email,
        },
      ) as Map<String, dynamic>;

      return data['message'] ?? 'A password reset link has been sent to your registered email address.';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to send reset link');
    }
  }

  /// Submit a new password using the token received via email.
  Future<String> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final data = await apiClient.post(
        '/reset-password',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      ) as Map<String, dynamic>;

      return data['message'] ?? 'Your password has been reset successfully! You can now log in.';
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to reset password');
    }
  }


  Future<void> logOut() async {
    final token = await _getToken();
    if (token != null) {
      try {
        await apiClient.post(ApiConstants.logout);
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
      final data = await apiClient.get(ApiConstants.user) as Map<String, dynamic>?;
      if (data != null) {
        final user = UserModel.fromJson(data);
        await _saveUserLocally(user);
        _userController.add(user);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logOut();
      }
    } catch (_) {}
  }

  Future<UserModel?> _fetchUserFromServer(String token) async {
    try {
      final data = await apiClient.get(ApiConstants.user) as Map<String, dynamic>?;
      if (data == null) {
        await logOut();
        return null;
      }
      final user = UserModel.fromJson(data);
      await _saveUserLocally(user);
      return user;
    } on ApiException {
      await logOut();
      return null;
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
      _refreshUserInBackground(token);
      return UserModel(id: 0, name: 'User');
    }

    return _fetchUserFromServer(token);
  }

  Future<UserModel> uploadProfilePhoto(String filePath) async {
    try {
      final data = await apiClient.postMultipart(
        '/profile/photo',
        files: {'profile_photo': filePath},
      ) as Map<String, dynamic>;

      final user = UserModel.fromJson(data['user']);
      await _saveUserLocally(user);
      return user;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Profile photo upload failed');
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

    try {
      final data = await apiClient.put('/profile', body: body) as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user']);
      await _saveUserLocally(user);
      return user;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to update profile');
    }
  }

  Future<List<UserModel>> getPlayers({String? search}) async {
    final queryParams = search != null && search.isNotEmpty ? {'search': search} : null;

    try {
      final data = await apiClient.get(ApiConstants.players, queryParams: queryParams) as Map<String, dynamic>;
      final List<dynamic> playersJson = data['data'];
      return playersJson.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to fetch players');
    }
  }

  Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    try {
      return await apiClient.get('/users/$userId') as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> waveUser(int userId) async {
    try {
      await apiClient.post('/users/$userId/wave');
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to send wave');
    }
  }

  Future<UserStats> getUserStats() async {
    try {
      final data = await apiClient.get('/user/stats') as Map<String, dynamic>;
      return UserStats.fromJson(data);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to fetch user stats');
    }
  }

  Future<List<MatchModel>> getUserHistory() async {
    try {
      final List<dynamic> data = await apiClient.get('/user/history') as List<dynamic>;
      return data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to fetch user history');
    }
  }

  Future<List<dynamic>> getUserRatings() async {
    try {
      return await apiClient.get('/user/ratings') as List<dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('Failed to fetch user ratings');
    }
  }

  void dispose() {
    _controller.close();
    _userController.close();
  }
}
