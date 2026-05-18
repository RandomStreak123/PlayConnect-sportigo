class MatchModel {
  final String id;
  final String sportType;
  final String title;
  final String dateTime;
  final String location;
  final int availableSlots;
  final String skillLevel;
  final List<String> avatars;
  final double distance;
  final String? organizer;

  int get slotsLeft {
    return availableSlots;
  }

  DateTime get parsedDateTime {
    return DateTime.tryParse(dateTime) ?? DateTime.now();
  }

  MatchModel({
    required this.id,
    required this.sportType,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.availableSlots,
    required this.skillLevel,
    required this.avatars,
    required this.distance,
    this.organizer,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'].toString(),
      sportType: json['sport_type'],
      title: json['title'],
      dateTime: json['date_time'],
      location: json['location'],
      availableSlots: json['available_slots'],
      skillLevel: json['skill_level'],
      avatars:
          (json['users'] as List?)
              ?.map(
                (u) =>
                    u['profile_picture'] as String? ??
                    'assets/images/avatars/avatar1.png',
              )
              .toList() ??
          [],
      distance: (json['distance'] ?? 0.0).toDouble(),
      organizer:
          (json['organizer_name'] as String?) ??
          (((json['users'] as List?)?.isNotEmpty ?? false)
              ? (json['users'] as List).first['name'] as String?
              : null),
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
      'skill_level': skillLevel,
    };
  }

  MatchModel copyWith({
    String? id,
    String? sportType,
    String? title,
    String? dateTime,
    String? location,
    int? availableSlots,
    String? skillLevel,
    List<String>? avatars,
    double? distance,
    String? organizer,
  }) {
    return MatchModel(
      id: id ?? this.id,
      sportType: sportType ?? this.sportType,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      availableSlots: availableSlots ?? this.availableSlots,
      skillLevel: skillLevel ?? this.skillLevel,
      avatars: avatars ?? this.avatars,
      distance: distance ?? this.distance,
      organizer: organizer ?? this.organizer,
    );
  }
}
