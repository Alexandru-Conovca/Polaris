import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/location_service.dart';
import 'package:polaris/data/result.dart';
import 'package:polaris/models/observation_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ObservationLocation', () {
    test('serializes and restores device metadata', () {
      final timestamp = DateTime.utc(2026, 11, 24, 12);
      final location = ObservationLocation.device(
        latitude: 47.01,
        longitude: 28.86,
        altitude: 85.5,
        accuracy: 3.2,
        speed: 0,
        heading: 120,
        timestamp: timestamp,
      );

      final restored = ObservationLocation.fromJson(location.toJson());

      expect(restored.latitude, location.latitude);
      expect(restored.longitude, location.longitude);
      expect(restored.altitude, location.altitude);
      expect(restored.accuracy, location.accuracy);
      expect(restored.speed, location.speed);
      expect(restored.heading, location.heading);
      expect(restored.timestamp, timestamp);
      expect(restored.source, ObservationLocationSource.device);
    });

    test('persists and restores the observation site offline', () async {
      final service = LocationService();
      final location = ObservationLocation.manual(
        latitude: 47.01,
        longitude: 28.86,
        altitude: 85,
        timestamp: DateTime.utc(2026, 11, 24),
      );

      expect(await service.saveLocation(location), isA<Ok<void>>());

      final result = await service.loadSavedLocation();
      expect(result, isA<Ok<ObservationLocation?>>());
      final restored = (result as Ok<ObservationLocation?>).value!;
      expect(restored.latitude, location.latitude);
      expect(restored.longitude, location.longitude);
      expect(restored.altitude, location.altitude);
      expect(restored.source, ObservationLocationSource.manual);
    });

    test('reports invalid persisted data instead of accepting it', () async {
      SharedPreferences.setMockInitialValues({
        'observation_location': jsonEncode({
          'latitude': 0,
          'longitude': 0,
          'timestamp': '2026-11-24T00:00:00.000Z',
          'source': 'unknown',
        }),
      });

      final result = await LocationService().loadSavedLocation();

      expect(result, isA<Err<ObservationLocation?>>());
    });

    test(
      'manual location allows omitted altitude and validates coordinates',
      () {
        final location = ObservationLocation.manual(
          latitude: 90,
          longitude: -180,
          timestamp: DateTime.utc(2026),
        );

        expect(location.altitude, isNull);
        expect(location.source, ObservationLocationSource.manual);
        expect(
          () => ObservationLocation.manual(
            latitude: 90.01,
            longitude: 0,
            timestamp: DateTime.utc(2026),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
