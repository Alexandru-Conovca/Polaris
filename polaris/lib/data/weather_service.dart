import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/observation_location.dart';
import '../models/weather_snapshot.dart';
import 'result.dart';

class WeatherService {
  WeatherService({http.Client? client, DateTime Function()? clock})
    : _client = client ?? http.Client(),
      _clock = clock ?? DateTime.now;

  static const _timeout = Duration(seconds: 12);
  static const _hourlyVariables = [
    'temperature_2m',
    'relative_humidity_2m',
    'dew_point_2m',
    'cloud_cover',
    'cloud_cover_low',
    'cloud_cover_mid',
    'cloud_cover_high',
    'wind_speed_10m',
    'wind_gusts_10m',
    'precipitation_probability',
  ];

  final http.Client _client;
  final DateTime Function() _clock;

  Future<Result<WeatherSnapshot>> fetch(ObservationLocation location) async {
    final query = <String, String>{
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'hourly': _hourlyVariables.join(','),
      'timezone': 'UTC',
      'forecast_days': '2',
      if (location.altitude != null) 'elevation': '${location.altitude}',
    };

    try {
      final response = await _client
          .get(Uri.https('api.open-meteo.com', '/v1/forecast', query))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        return const Err('Сервис погоды временно недоступен.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = body['hourly'] as Map<String, dynamic>;
      final times = hourly['time'] as List;
      if (times.isEmpty) {
        return const Err('Сервис погоды не вернул почасовой прогноз.');
      }

      final index = _nearestForecastIndex(times);
      final forecastAt = _parseUtc(times[index] as String);

      double? field(String key) {
        final values = hourly[key];
        if (values == null) {
          return null;
        }
        if (values is! List || index >= values.length) {
          throw const FormatException('Unexpected hourly weather data');
        }
        final value = values[index];
        if (value == null) {
          return null;
        }
        if (value is! num || !value.toDouble().isFinite) {
          throw const FormatException('Unexpected hourly weather value');
        }
        return value.toDouble();
      }

      return Ok(
        WeatherSnapshot(
          latitude: location.latitude,
          longitude: location.longitude,
          fetchedAt: _clock().toUtc(),
          forecastAt: forecastAt,
          temperatureC: field('temperature_2m'),
          dewPointC: field('dew_point_2m'),
          cloudCover: field('cloud_cover'),
          cloudCoverLow: field('cloud_cover_low'),
          cloudCoverMid: field('cloud_cover_mid'),
          cloudCoverHigh: field('cloud_cover_high'),
          relativeHumidity: field('relative_humidity_2m'),
          windSpeedKmh: field('wind_speed_10m'),
          windGustKmh: field('wind_gusts_10m'),
          precipitationProbability: field('precipitation_probability'),
        ),
      );
    } on SocketException {
      return const Err('Нет сети — показываются последние сохранённые данные.');
    } on TimeoutException {
      return const Err('Сервис погоды не ответил вовремя.');
    } on http.ClientException {
      return const Err('Не удалось подключиться к сервису погоды.');
    } on FormatException {
      return const Err('Сервис погоды вернул данные в неизвестном формате.');
    } on TypeError {
      return const Err('Сервис погоды вернул данные в неизвестном формате.');
    }
  }

  int _nearestForecastIndex(List<dynamic> times) {
    final now = _clock().toUtc();
    var nearestIndex = -1;
    var closestDifference = const Duration(days: 3);
    for (var index = 0; index < times.length; index++) {
      final value = times[index];
      final forecastTime = _parseUtc(value as String);
      final difference = forecastTime.difference(now).abs();
      if (difference < closestDifference) {
        nearestIndex = index;
        closestDifference = difference;
      }
    }
    if (nearestIndex < 0) {
      throw const FormatException('No valid forecast timestamps');
    }
    return nearestIndex;
  }

  DateTime _parseUtc(String value) {
    final parsed = DateTime.parse(value);
    return parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
  }
}
