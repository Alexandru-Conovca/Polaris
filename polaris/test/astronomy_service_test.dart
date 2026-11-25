import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/astronomy_service.dart';
import 'package:polaris/data/celestial_object.dart';
import 'package:polaris/models/domain_models.dart';
import 'package:polaris/models/observation_location.dart';

void main() {
  const service = AstronomyService();

  test('parses sexagesimal RA and signed declination', () {
    final coordinates = EquatorialCoordinates.tryParse(
      'RA 18h 36m 56s, Dec +38° 47′ 01″',
    );

    expect(coordinates, isNotNull);
    expect(coordinates!.rightAscensionHours, closeTo(18.61556, 0.00001));
    expect(coordinates.declinationDegrees, closeTo(38.78361, 0.00001));
  });

  test('does not calculate visibility when declination is missing', () {
    expect(EquatorialCoordinates.tryParse('RA 05h'), isNull);
  });

  test('converts an object at the zenith to horizontal coordinates', () {
    final position = service.calculate(
      rightAscensionHours: 18.697374558,
      declinationDegrees: 0,
      latitudeDegrees: 0,
      longitudeDegrees: 0,
      at: DateTime.utc(2000, 1, 1, 12),
    );

    expect(position.altitudeDegrees, closeTo(90, 0.01));
    expect(position.azimuthDegrees, inInclusiveRange(0, 360));
    expect(position.status, VisibilityStatus.high);
  });

  test(
    'marks below-horizon objects and supports the visible-now threshold',
    () {
      final position = service.calculate(
        rightAscensionHours: 6,
        declinationDegrees: 0,
        latitudeDegrees: 0,
        longitudeDegrees: 0,
        at: DateTime.utc(2000, 1, 1, 12),
      );

      expect(position.altitudeDegrees, lessThan(0));
      expect(position.status, VisibilityStatus.belowHorizon);
      expect(position.isVisibleNow, isFalse);
    },
  );

  test('accounts for observer elevation when estimating the horizon', () {
    final seaLevel = service.calculate(
      rightAscensionHours: 18.5,
      declinationDegrees: 0,
      latitudeDegrees: 0,
      longitudeDegrees: 0,
      at: DateTime.utc(2000, 1, 1, 12),
    );
    final elevated = service.calculate(
      rightAscensionHours: 18.5,
      declinationDegrees: 0,
      latitudeDegrees: 0,
      longitudeDegrees: 0,
      observerAltitudeMeters: 1000,
      at: DateTime.utc(2000, 1, 1, 12),
    );

    expect(elevated.altitudeDegrees, greaterThan(seaLevel.altitudeDegrees));
  });

  test('uses parsed object coordinates and current observer location', () {
    final object = CelestialObject(
      id: 'm31',
      name: 'Andromeda',
      type: CelestialType.galaxy,
      description: '',
      magnitude: 3.4,
      coordinates: 'RA 00h 42m 44s, Dec +41° 16′ 09″',
      constellation: 'Andromeda',
      isVisibleNow: false,
    );
    final site = ObservationLocation.manual(
      latitude: 47,
      longitude: 28,
      timestamp: DateTime.utc(2026),
    );

    expect(
      service.positionFor(
        object: object,
        location: site,
        at: DateTime.utc(2026, 11, 24),
      ),
      isNotNull,
    );
  });
}
