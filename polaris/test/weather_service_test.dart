import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:polaris/data/result.dart';
import 'package:polaris/data/weather_service.dart';
import 'package:polaris/models/observation_location.dart';
import 'package:polaris/models/weather_model.dart';
import 'package:polaris/models/weather_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'requests astronomy-relevant hourly fields and selects nearest hour',
    () async {
      final service = WeatherService(
        client: MockClient((request) async {
          expect(request.url.host, 'api.open-meteo.com');
          expect(request.url.queryParameters['elevation'], '123.0');
          expect(
            request.url.queryParameters['hourly'],
            contains('dew_point_2m'),
          );
          expect(
            request.url.queryParameters['hourly'],
            contains('precipitation_probability'),
          );
          return http.Response(
            jsonEncode({
              'hourly': {
                'time': ['2026-01-01T12:00', '2026-01-01T13:00'],
                'temperature_2m': [4, 5],
                'relative_humidity_2m': [70, 72],
                'dew_point_2m': [1, 2],
                'cloud_cover': [20, 30],
                'cloud_cover_low': [10, 15],
                'cloud_cover_mid': [5, 10],
                'cloud_cover_high': [15, 20],
                'wind_speed_10m': [8, 9],
                'wind_gusts_10m': [14, 15],
                'precipitation_probability': [0, 10],
              },
            }),
            200,
          );
        }),
        clock: () => DateTime.utc(2026, 1, 1, 12, 10),
      );

      final result = await service.fetch(
        ObservationLocation.manual(
          latitude: 47,
          longitude: 28,
          altitude: 123,
          timestamp: DateTime.utc(2026),
        ),
      );

      expect(result, isA<Ok<WeatherSnapshot>>());
      final weather = (result as Ok<WeatherSnapshot>).value;
      expect(weather.temperatureC, 4);
      expect(weather.dewPointC, 1);
      expect(weather.cloudCoverLow, 10);
      expect(weather.precipitationProbability, 0);
      expect(weather.forecastAt, DateTime.utc(2026, 1, 1, 12));
      expect(weather.fetchedAt, DateTime.utc(2026, 1, 1, 12, 10));
    },
  );

  test('uses the cached observation weather when the API is offline', () async {
    final location = ObservationLocation.manual(
      latitude: 47,
      longitude: 28,
      altitude: 123,
      timestamp: DateTime.utc(2026, 1, 1),
    );
    final cached = WeatherSnapshot(
      latitude: location.latitude,
      longitude: location.longitude,
      fetchedAt: DateTime.utc(2026, 1, 1, 12),
      forecastAt: DateTime.utc(2026, 1, 1, 12),
      temperatureC: 4,
      dewPointC: 1,
      cloudCover: 20,
      relativeHumidity: 70,
      windSpeedKmh: 8,
      windGustKmh: 14,
      precipitationProbability: 0,
    );
    SharedPreferences.setMockInitialValues({
      'observation_location': jsonEncode(location.toJson()),
      'weather_snapshot_v1': jsonEncode(cached.toJson()),
    });
    final model = WeatherModel(
      weatherService: WeatherService(
        client: MockClient((_) async => throw SocketException('offline')),
      ),
    );

    await model.load();
    await pumpEventQueue();

    expect(model.currentWeather?.temperatureC, 4);
    expect(model.weatherErrorMessage, contains('Нет сети'));
  });
}
