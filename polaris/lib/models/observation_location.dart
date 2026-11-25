enum ObservationLocationSource { device, manual }

class ObservationLocation {
  const ObservationLocation._({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
  });

  factory ObservationLocation.device({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    double? altitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) => _create(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    source: ObservationLocationSource.device,
    altitude: _finiteOrNull(altitude),
    accuracy: _nonNegativeOrNull(accuracy),
    speed: _nonNegativeOrNull(speed),
    heading: heading != null && heading >= 0 && heading <= 360 ? heading : null,
  );

  factory ObservationLocation.manual({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    double? altitude,
  }) => _create(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    source: ObservationLocationSource.manual,
    altitude: altitude,
  );

  factory ObservationLocation.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String;
    final source = ObservationLocationSource.values.byName(sourceName);
    return _create(
      latitude: _requiredDouble(json, 'latitude'),
      longitude: _requiredDouble(json, 'longitude'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: source,
      altitude: _optionalDouble(json, 'altitude'),
      accuracy: _optionalDouble(json, 'accuracy'),
      speed: _optionalDouble(json, 'speed'),
      heading: _optionalDouble(json, 'heading'),
    );
  }

  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final ObservationLocationSource source;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'source': source.name,
  };

  static ObservationLocation _create({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required ObservationLocationSource source,
    double? altitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90',
      );
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180',
      );
    }
    for (final entry in {
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
    }.entries) {
      if (entry.value != null && !entry.value!.isFinite) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be finite');
      }
    }
    if (accuracy != null && accuracy < 0) {
      throw ArgumentError.value(accuracy, 'accuracy', 'Must not be negative');
    }
    if (speed != null && speed < 0) {
      throw ArgumentError.value(speed, 'speed', 'Must not be negative');
    }
    if (heading != null && (heading < 0 || heading > 360)) {
      throw ArgumentError.value(
        heading,
        'heading',
        'Must be between 0 and 360',
      );
    }
    return ObservationLocation._(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      source: source,
      altitude: altitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
    );
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('Expected a number for $key');
    }
    return value.toDouble();
  }

  static double? _optionalDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! num) {
      throw FormatException('Expected a number for $key');
    }
    return value.toDouble();
  }

  static double? _finiteOrNull(double? value) =>
      value != null && value.isFinite ? value : null;

  static double? _nonNegativeOrNull(double? value) =>
      value != null && value.isFinite && value >= 0 ? value : null;
}
