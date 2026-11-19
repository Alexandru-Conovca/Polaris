enum CelestialType { planet, galaxy, nebula, star }

enum QuestDifficulty { beginner, intermediate, advanced }

class User {
  const User({required this.name, required this.email, required this.level});

  final String name;
  final String email;
  final String level;
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.tasksCount,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final QuestDifficulty difficulty;
  final int tasksCount;
  final String createdAt;
}

class Observation {
  const Observation({
    required this.id,
    required this.objectName,
    required this.dateTime,
    required this.location,
    required this.status,
    required this.questTitle,
  });

  final String id;
  final String objectName;
  final String dateTime;
  final String location;
  final String status;
  final String questTitle;
}

class Telescope {
  const Telescope({
    required this.id,
    required this.name,
    required this.aperture,
    required this.focalLength,
    required this.mountType,
  });

  final String id;
  final String name;
  final int aperture;
  final int focalLength;
  final String mountType;

  factory Telescope.fromJson(Map<String, dynamic> json) => Telescope(
    id: '${json['id']}',
    name: json['name'] as String,
    aperture: (json['aperture'] as num).toInt(),
    focalLength: (json['focalLength'] as num).toInt(),
    mountType: json['mountType'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'aperture': aperture,
    'focalLength': focalLength,
    'mountType': mountType,
  };

  Telescope copyWith({int? aperture, int? focalLength, String? mountType}) =>
      Telescope(
        id: id,
        name: name,
        aperture: aperture ?? this.aperture,
        focalLength: focalLength ?? this.focalLength,
        mountType: mountType ?? this.mountType,
      );
}
