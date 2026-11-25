import 'dart:math' as math;

import '../models/observation_location.dart';
import 'celestial_object.dart';

class EquatorialCoordinates {
  const EquatorialCoordinates({
    required this.rightAscensionHours,
    required this.declinationDegrees,
  });

  final double rightAscensionHours;
  final double declinationDegrees;

  static final _rightAscensionPattern = RegExp(
    r'''\bRA\s*[:=]?\s*(\d+(?:\.\d+)?)(?:\s*(?:h|:)\s*(\d+(?:\.\d+)?)(?:\s*(?:m|:)\s*(\d+(?:\.\d+)?)\s*s?)?)?''',
    caseSensitive: false,
  );
  static final _declinationPattern = RegExp(
    r'''\bDec\s*[:=]?\s*([+-]?\d+(?:\.\d+)?)(?:\s*(?:°|d|:)\s*(\d+(?:\.\d+)?)(?:\s*(?:′|'|m|:)\s*(\d+(?:\.\d+)?)\s*(?:″|"|s)?)?)?''',
    caseSensitive: false,
  );

  static EquatorialCoordinates? tryParse(String value) {
    final raMatch = _rightAscensionPattern.firstMatch(value);
    final decMatch = _declinationPattern.firstMatch(value);
    if (raMatch == null || decMatch == null) {
      return null;
    }

    final raHours = _sexagesimal(
      raMatch.group(1),
      raMatch.group(2),
      raMatch.group(3),
      negative: false,
    );
    final decDegrees = _sexagesimal(
      decMatch.group(1),
      decMatch.group(2),
      decMatch.group(3),
      negative: decMatch.group(1)!.startsWith('-'),
    );
    if (raHours == null ||
        decDegrees == null ||
        raHours < 0 ||
        raHours > 24 ||
        decDegrees < -90 ||
        decDegrees > 90) {
      return null;
    }
    return EquatorialCoordinates(
      rightAscensionHours: raHours == 24 ? 0 : raHours,
      declinationDegrees: decDegrees,
    );
  }

  static double? _sexagesimal(
    String? first,
    String? second,
    String? third, {
    required bool negative,
  }) {
    if (first == null) {
      return null;
    }
    final primary = double.tryParse(first.replaceFirst(RegExp(r'^[+-]'), ''));
    final minutes = second == null ? 0 : double.tryParse(second);
    final seconds = third == null ? 0 : double.tryParse(third);
    if (primary == null ||
        minutes == null ||
        seconds == null ||
        minutes < 0 ||
        minutes >= 60 ||
        seconds < 0 ||
        seconds >= 60) {
      return null;
    }
    final magnitude = primary + minutes / 60 + seconds / 3600;
    return negative ? -magnitude : magnitude;
  }
}

enum VisibilityStatus { belowHorizon, low, visible, high }

class HorizontalPosition {
  const HorizontalPosition({
    required this.azimuthDegrees,
    required this.altitudeDegrees,
    required this.status,
  });

  final double azimuthDegrees;
  final double altitudeDegrees;
  final VisibilityStatus status;

  bool get isVisibleNow => altitudeDegrees > 15;

  String get statusLabel => switch (status) {
    VisibilityStatus.belowHorizon => 'За горизонтом',
    VisibilityStatus.low => 'Низко над горизонтом',
    VisibilityStatus.visible => 'Виден сейчас',
    VisibilityStatus.high => 'Высоко в небе',
  };
}

class AstronomyService {
  const AstronomyService();

  String brightnessHint(double magnitude) => switch (magnitude) {
    < 1 => 'Очень яркий',
    < 3 => 'Яркий',
    < 6 => 'Нужны тёмное небо и хорошая прозрачность',
    _ => 'Может потребоваться оптический инструмент',
  };

  HorizontalPosition? positionFor({
    required CelestialObject object,
    required ObservationLocation location,
    DateTime? at,
  }) {
    final coordinates = EquatorialCoordinates.tryParse(object.coordinates);
    if (coordinates == null) {
      return null;
    }
    return calculate(
      rightAscensionHours: coordinates.rightAscensionHours,
      declinationDegrees: coordinates.declinationDegrees,
      latitudeDegrees: location.latitude,
      longitudeDegrees: location.longitude,
      observerAltitudeMeters: location.altitude ?? 0,
      at: at ?? DateTime.now().toUtc(),
    );
  }

  HorizontalPosition calculate({
    required double rightAscensionHours,
    required double declinationDegrees,
    required double latitudeDegrees,
    required double longitudeDegrees,
    double observerAltitudeMeters = 0,
    required DateTime at,
  }) {
    final utc = at.toUtc();
    final julianDate =
        utc.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;
    final centuries = (julianDate - 2451545.0) / 36525.0;
    final greenwichSiderealDegrees = _normalizeDegrees(
      280.46061837 +
          360.98564736629 * (julianDate - 2451545.0) +
          0.000387933 * centuries * centuries -
          centuries * centuries * centuries / 38710000,
    );
    final localSiderealDegrees = _normalizeDegrees(
      greenwichSiderealDegrees + longitudeDegrees,
    );
    final hourAngleDegrees = _normalizeSignedDegrees(
      localSiderealDegrees - rightAscensionHours * 15,
    );

    final latitude = _radians(latitudeDegrees);
    final declination = _radians(declinationDegrees);
    final hourAngle = _radians(hourAngleDegrees);
    final altitude = math.asin(
      (math.sin(latitude) * math.sin(declination) +
              math.cos(latitude) * math.cos(declination) * math.cos(hourAngle))
          .clamp(-1.0, 1.0),
    );
    final azimuth = math.atan2(
      math.sin(hourAngle),
      math.cos(hourAngle) * math.sin(latitude) -
          math.tan(declination) * math.cos(latitude),
    );
    final geometricAltitudeDegrees = _degrees(altitude);
    final altitudeMeters = observerAltitudeMeters.isFinite
        ? math.max(0, observerAltitudeMeters).toDouble()
        : 0;
    final horizonDipDegrees = _degrees(
      math.acos(6371000 / (6371000 + altitudeMeters)),
    );
    final altitudeDegrees = math
        .min(90, geometricAltitudeDegrees + horizonDipDegrees)
        .toDouble();
    final azimuthDegrees = _normalizeDegrees(_degrees(azimuth) + 180);

    final status = switch (altitudeDegrees) {
      < 0 => VisibilityStatus.belowHorizon,
      < 15 => VisibilityStatus.low,
      >= 60 => VisibilityStatus.high,
      _ => VisibilityStatus.visible,
    };
    return HorizontalPosition(
      azimuthDegrees: azimuthDegrees,
      altitudeDegrees: altitudeDegrees,
      status: status,
    );
  }

  double _normalizeDegrees(double value) => (value % 360 + 360) % 360;

  double _normalizeSignedDegrees(double value) =>
      _normalizeDegrees(value + 180) - 180;

  double _radians(double degrees) => degrees * math.pi / 180;

  double _degrees(double radians) => radians * 180 / math.pi;
}
