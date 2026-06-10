class ApiConstants {
  /// Override at build time: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api'
  );

  /// Base URL for storage assets (without /api suffix).
  static String get assetBaseUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';

  // Match endpoints
  static const String matches = '/matches';
  static const String myMatches = '/matches/mine';
  static String joinMatch(String id) => '/matches/$id/join';
  static String leaveMatch(String id) => '/matches/$id/leave';

  // Activity endpoints
  static const String activities = '/activities';
}
