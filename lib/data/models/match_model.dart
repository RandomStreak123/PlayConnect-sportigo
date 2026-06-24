import 'dart:math' as math;

class MatchParticipant {
  final int id;
  final String name;
  final String? profilePicture;
  final String? result;

  const MatchParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
    this.result,
  });

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;
    return MatchParticipant(
      id: json['id'] as int,
      name: json['name'] as String,
      profilePicture: (json['profile_picture'] as String?) ?? 
                      (json['profilePicture'] as String?) ?? 
                      (json['avatar'] as String?),
      result: (pivot != null ? pivot['result'] : json['result']) as String?,
    );
  }
}

class MatchModel {
  final String id;
  final String sportType;
  final String title;
  final String dateTime;
  final String location;
  final int availableSlots;
  final int maxSlots;
  final int joinedCount;
  final String skillLevel;
  final List<MatchParticipant> participants;
  final double distance;
  final String? organizer;
  final String? organizerPhoto;
  final bool womenOnly;
  final int? creatorId;

  /// Open spots — prefer server `slots_left`, else capacity minus joined count.
  int get slotsLeft => math.max(0, maxSlots - joinedCount);

  DateTime get parsedDateTime {
    return DateTime.tryParse(dateTime) ?? DateTime.now();
  }

  bool get isPast {
    return parsedDateTime.isBefore(DateTime.now());
  }

  bool isJoinedBy(int? userId) {
    if (userId == null) return false;
    return participants.any((p) => p.id == userId);
  }

  List<String> get avatars => participants
      .map((p) => p.profilePicture ?? 'assets/images/player_profile.png')
      .toList();

  MatchModel({
    required this.id,
    required this.sportType,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.availableSlots,
    required this.maxSlots,
    required this.joinedCount,
    required this.skillLevel,
    required this.participants,
    required this.distance,
    this.organizer,
    this.organizerPhoto,
    this.womenOnly = false,
    this.creatorId,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final participants = (json['users'] as List?)
            ?.map((u) => MatchParticipant.fromJson(u as Map<String, dynamic>))
            .toList() ??
        [];

    final available = json['available_slots'] as int;
    final apiJoined = json['joined_count'] as int?;
    final joinedCount = apiJoined ?? participants.length;
    final maxSlots =
        json['max_slots'] as int? ?? math.max(joinedCount, available + joinedCount);

    return MatchModel(
      id: json['id'].toString(),
      sportType: json['sport_type'],
      title: json['title'],
      dateTime: json['date_time'],
      location: json['location'],
      availableSlots: json['slots_left'] as int? ?? available,
      maxSlots: maxSlots,
      joinedCount: joinedCount,
      skillLevel: json['skill_level'],
      participants: participants,
      distance: (json['distance'] ?? 0.0).toDouble(),
      organizer:
          (json['organizer'] as String?) ??
          (json['organizer_name'] as String?) ??
          (participants.isNotEmpty ? participants.first.name : null),
      organizerPhoto:
          (json['organizer_photo'] as String?) ??
          (json['user']?['profile_picture'] as String?) ??
          (json['user']?['avatar'] as String?),
      womenOnly: json['women_only'] == 1 || json['women_only'] == true,
      creatorId: json['creator_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sport_type': sportType,
      'title': title,
      'date_time': dateTime,
      'location': location,
      'available_slots': availableSlots,
      'max_slots': maxSlots,
      'joined_count': joinedCount,
      'skill_level': skillLevel,
      'women_only': womenOnly,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'sport_type': sportType,
      'title': title,
      'date_time': dateTime,
      'location': location,
      'available_slots': availableSlots,
      'skill_level': skillLevel,
      'women_only': womenOnly,
    };
  }

  MatchModel copyWith({
    String? id,
    String? sportType,
    String? title,
    String? dateTime,
    String? location,
    int? availableSlots,
    int? maxSlots,
    int? joinedCount,
    String? skillLevel,
    List<MatchParticipant>? participants,
    double? distance,
    String? organizer,
    String? organizerPhoto,
    bool? womenOnly,
    int? creatorId,
  }) {
    return MatchModel(
      id: id ?? this.id,
      sportType: sportType ?? this.sportType,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      availableSlots: availableSlots ?? this.availableSlots,
      maxSlots: maxSlots ?? this.maxSlots,
      joinedCount: joinedCount ?? this.joinedCount,
      skillLevel: skillLevel ?? this.skillLevel,
      participants: participants ?? this.participants,
      distance: distance ?? this.distance,
      organizer: organizer ?? this.organizer,
      organizerPhoto: organizerPhoto ?? this.organizerPhoto,
      womenOnly: womenOnly ?? this.womenOnly,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
