import 'celestial_object.dart';
import 'result.dart';

abstract class CelestialObjectRepository {
  Future<Result<List<CelestialObject>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<CelestialObject>> fetchById(String id);

  Future<Result<CelestialObject>> create(CelestialObject object);

  Future<Result<CelestialObject>> update(CelestialObject object);

  Future<Result<void>> delete(String id);
}
