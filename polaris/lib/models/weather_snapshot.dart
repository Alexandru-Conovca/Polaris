class WeatherSnapshot {
  const WeatherSnapshot({
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.forecastAt,
    this.temperatureC,
    this.dewPointC,
    this.cloudCover,
    this.cloudCoverLow,
    this.cloudCoverMid,
    this.cloudCoverHigh,
    this.relativeHumidity,
    this.windSpeedKmh,
    this.windGustKmh,
    this.precipitationProbability,
  });

  final double latitude;
  final double longitude;
  final DateTime fetchedAt;
  final DateTime forecastAt;
  final double? temperatureC;
  final double? dewPointC;
  final double? cloudCover;
  final double? cloudCoverLow;
  final double? cloudCoverMid;
  final double? cloudCoverHigh;
  final double? relativeHumidity;
  final double? windSpeedKmh;
  final double? windGustKmh;
  final double? precipitationProbability;

  bool matchesLocation(double otherLatitude, double otherLongitude) =>
      (latitude - otherLatitude).abs() < 0.000001 &&
      (longitude - otherLongitude).abs() < 0.000001;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'forecastAt': forecastAt.toIso8601String(),
    'temperatureC': temperatureC,
    'dewPointC': dewPointC,
    'cloudCover': cloudCover,
    'cloudCoverLow': cloudCoverLow,
    'cloudCoverMid': cloudCoverMid,
    'cloudCoverHigh': cloudCoverHigh,
    'relativeHumidity': relativeHumidity,
    'windSpeedKmh': windSpeedKmh,
    'windGustKmh': windGustKmh,
    'precipitationProbability': precipitationProbability,
  };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        latitude: _number(json, 'latitude'),
        longitude: _number(json, 'longitude'),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        forecastAt: DateTime.parse(json['forecastAt'] as String),
        temperatureC: _optionalNumber(json, 'temperatureC'),
        dewPointC: _optionalNumber(json, 'dewPointC'),
        cloudCover: _optionalNumber(json, 'cloudCover'),
        cloudCoverLow: _optionalNumber(json, 'cloudCoverLow'),
        cloudCoverMid: _optionalNumber(json, 'cloudCoverMid'),
        cloudCoverHigh: _optionalNumber(json, 'cloudCoverHigh'),
        relativeHumidity: _optionalNumber(json, 'relativeHumidity'),
        windSpeedKmh: _optionalNumber(json, 'windSpeedKmh'),
        windGustKmh: _optionalNumber(json, 'windGustKmh'),
        precipitationProbability: _optionalNumber(
          json,
          'precipitationProbability',
        ),
      );

  static double _number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException('Expected a finite number for $key');
    }
    return value.toDouble();
  }

  static double? _optionalNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! num || !value.toDouble().isFinite) {
      throw FormatException('Expected a finite number for $key');
    }
    return value.toDouble();
  }
}
