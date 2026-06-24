import '../../core/constants/api_constants.dart';

class UserModel {
  final int id;
  final String name;
  final String? username;
  final String? phoneNumber;
  final String? profilePicture;
  final String? gender;
  final bool hidePhone;
  final String? themePreference;
  final String? primarySport;
  final String? skillTier;
  final String? bio;
  final String? email;

  final UserStats? stats;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.phoneNumber,
    this.profilePicture,
    this.gender,
    this.hidePhone = false,
    this.themePreference = 'system',
    this.primarySport,
    this.skillTier,
    this.bio,
    this.email,
    this.stats,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? phoneNumber,
    String? profilePicture,
    String? gender,
    bool? hidePhone,
    String? themePreference,
    String? primarySport,
    String? skillTier,
    String? bio,
    String? email,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      gender: gender ?? this.gender,
      hidePhone: hidePhone ?? this.hidePhone,
      themePreference: themePreference ?? this.themePreference,
      primarySport: primarySport ?? this.primarySport,
      skillTier: skillTier ?? this.skillTier,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      stats: stats ?? this.stats,
    );
  }

  String? get profilePhotoUrl {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    if (profilePicture!.startsWith('assets/')) {
      return null;
    }
    if (profilePicture!.startsWith('http://') || profilePicture!.startsWith('https://')) {
      try {
        final uri = Uri.parse(profilePicture!);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final baseUri = Uri.parse(ApiConstants.assetBaseUrl);
          return uri.replace(
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          ).toString();
        }
      } catch (_) {
        final baseHost = Uri.parse(ApiConstants.assetBaseUrl).host;
        return profilePicture!.replaceAll('localhost', baseHost).replaceAll('127.0.0.1', baseHost);
      }
      return profilePicture;
    }
    return '${ApiConstants.assetBaseUrl}/storage/$profilePicture';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'] ?? json['profilePicture'] ?? json['avatar'],
      gender: json['gender'],
      hidePhone: json['hide_phone'] == 1 || json['hide_phone'] == true,
      themePreference: json['theme_preference'] ?? 'system',
      primarySport: json['primary_sport'],
      skillTier: json['skill_tier'],
      bio: json['bio'],
      email: json['email'],
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'gender': gender,
      'hide_phone': hidePhone ? 1 : 0,
      'theme_preference': themePreference,
      'primary_sport': primarySport,
      'skill_tier': skillTier,
      'bio': bio,
      'email': email,
      'stats': stats?.toJson(),
    };
  }
}

class UserStats {
  final int xp;
  final int level;
  final int currentLevelXp;
  final int nextLevelXp;
  final int progressPct;
  final int winRate;
  final int streak;
  final String playStyle;
  final String globalRank;
  final double averageRating;
  final int totalGames;

  UserStats({
    required this.xp,
    required this.level,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.progressPct,
    required this.winRate,
    required this.streak,
    required this.playStyle,
    required this.globalRank,
    required this.averageRating,
    required this.totalGames,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      currentLevelXp: json['currentLevelXp'] ?? 0,
      nextLevelXp: json['nextLevelXp'] ?? 1000,
      progressPct: json['progressPct'] ?? 0,
      winRate: json['winRate'] ?? 0,
      streak: json['streak'] ?? 0,
      playStyle: json['playStyle'] ?? 'All-Rounder',
      globalRank: json['globalRank'] ?? '#1000 Kochi',
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalGames: json['totalGames'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'level': level,
      'currentLevelXp': currentLevelXp,
      'nextLevelXp': nextLevelXp,
      'progressPct': progressPct,
      'winRate': winRate,
      'streak': streak,
      'playStyle': playStyle,
      'globalRank': globalRank,
      'averageRating': averageRating,
      'totalGames': totalGames,
    };
  }
}
