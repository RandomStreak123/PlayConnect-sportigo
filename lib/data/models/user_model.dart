class UserModel {
  final int id;
  final String name;
  final String? username;
  final String? phoneNumber;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.phoneNumber,
    this.profilePicture,
  });

  String? get profilePhotoUrl {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    if (profilePicture!.startsWith('assets/')) {
      return null;
    }
    if (profilePicture!.startsWith('http://') || profilePicture!.startsWith('https://')) {
      return profilePicture!.replaceAll('localhost', '10.0.2.2');
    }
    return 'http://10.0.2.2:8000/storage/$profilePicture';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
    };
  }
}
