import '../models/domain_models.dart';

class CelestialObject {
  const CelestialObject({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.magnitude,
    required this.coordinates,
    required this.constellation,
    required this.isVisibleNow,
  });

  final String id;
  final String name;
  final CelestialType type;
  final String description;
  final double magnitude;
  final String coordinates;
  final String constellation;
  final bool isVisibleNow;

  factory CelestialObject.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type =
        CelestialType.values
            .where((value) => value.name == typeName)
            .firstOrNull ??
        CelestialType.star;

    return CelestialObject(
      id: '${json['id']}',
      name: json['name'] as String,
      type: type,
      description: json['description'] as String? ?? '',
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0,
      coordinates: json['coordinates'] as String? ?? '',
      constellation: json['constellation'] as String? ?? '',
      isVisibleNow: json['isVisibleNow'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'description': description,
    'magnitude': magnitude,
    'coordinates': coordinates,
    'constellation': constellation,
    'isVisibleNow': isVisibleNow,
  };

  CelestialObject copyWith({
    String? id,
    String? name,
    CelestialType? type,
    String? description,
    double? magnitude,
    String? coordinates,
    String? constellation,
    bool? isVisibleNow,
  }) => CelestialObject(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    description: description ?? this.description,
    magnitude: magnitude ?? this.magnitude,
    coordinates: coordinates ?? this.coordinates,
    constellation: constellation ?? this.constellation,
    isVisibleNow: isVisibleNow ?? this.isVisibleNow,
  );
}
