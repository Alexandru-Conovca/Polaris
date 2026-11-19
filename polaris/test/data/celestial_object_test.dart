import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/celestial_object.dart';
import 'package:polaris/models/domain_models.dart';

void main() {
  test('CelestialObject maps integer JSON fields and omits id in toJson', () {
    final object = CelestialObject.fromJson({
      'id': 12,
      'name': 'Mars',
      'type': 'planet',
      'description': 'Red planet',
      'magnitude': -1,
      'coordinates': 'RA 10h',
      'constellation': 'Leo',
      'isVisibleNow': true,
    });

    expect(object.id, '12');
    expect(object.type, CelestialType.planet);
    expect(object.magnitude, -1.0);
    expect(object.isVisibleNow, isTrue);
    expect(object.toJson().containsKey('id'), isFalse);
  });

  test('CelestialObject uses safe JSON defaults', () {
    final object = CelestialObject.fromJson({
      'id': 1,
      'name': 'Unknown',
      'type': 'unknown',
    });

    expect(object.type, CelestialType.star);
    expect(object.description, '');
    expect(object.magnitude, 0);
  });
}
