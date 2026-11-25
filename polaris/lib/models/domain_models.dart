enum CelestialType { planet, galaxy, nebula, star }

enum QuestDifficulty { beginner, intermediate, advanced }

class User {
  const User({required this.name, required this.email});

  final String name;
  final String email;
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.tasksCount,
  });

  final String id;
  final String title;
  final String description;
  final QuestDifficulty difficulty;
  final int tasksCount;
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
