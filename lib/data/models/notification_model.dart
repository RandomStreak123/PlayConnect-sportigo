class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? meta;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.meta,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      meta: json['meta'] is Map ? Map<String, dynamic>.from(json['meta']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'meta': meta,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
