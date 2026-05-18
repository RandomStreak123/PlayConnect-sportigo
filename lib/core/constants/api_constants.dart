class ApiConstants {
  // Use 10.0.2.2 for Android Emulator to access host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';
  
  // Match endpoints
  static const String matches = '/matches';
  static String joinMatch(String id) => '/matches/$id/join';
  static String leaveMatch(String id) => '/matches/$id/leave';
}
