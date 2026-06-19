import 'user_model.dart';

class ActivityModel {
  final int id;
  final int userId;
  final String type;
  final String message;
  final Map<String, dynamic>? meta;
  final DateTime createdAt;
  final UserModel? user;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.meta,
    required this.createdAt,
    this.user,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      type: json['type'],
      message: json['message'],
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] : null,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'meta': meta,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
