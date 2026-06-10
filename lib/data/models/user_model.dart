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
    );
  }

  String? get profilePhotoUrl {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    if (profilePicture!.startsWith('assets/')) {
      return null;
    }
    if (profilePicture!.startsWith('http://') || profilePicture!.startsWith('https://')) {
      final baseHost = Uri.parse(ApiConstants.assetBaseUrl).host;
      return profilePicture!.replaceAll('localhost', baseHost);
    }
    return '${ApiConstants.assetBaseUrl}/storage/$profilePicture';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      gender: json['gender'],
      hidePhone: json['hide_phone'] == 1 || json['hide_phone'] == true,
      themePreference: json['theme_preference'] ?? 'system',
      primarySport: json['primary_sport'],
      skillTier: json['skill_tier'],
      bio: json['bio'],
      email: json['email'],
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
    };
  }
}
