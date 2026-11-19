import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/celestial_object.dart';
import 'package:polaris/data/celestial_object_repository.dart';
import 'package:polaris/data/result.dart';
import 'package:polaris/models/celestial_objects_model.dart';
import 'package:polaris/models/domain_models.dart';

class _PagingRepository implements CelestialObjectRepository {
  int page = 1;
  int limit = 20;
  String? search;

  CelestialObject _object(int id) => CelestialObject(
    id: '$id',
    name: 'Object $id',
    type: CelestialType.star,
    description: '',
    magnitude: 1,
    coordinates: '',
    constellation: '',
    isVisibleNow: false,
  );

  @override
  Future<Result<List<CelestialObject>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    this.page = page;
    this.limit = limit;
    this.search = search;

    if (page == 1) {
      return Ok(List.generate(20, (index) => _object(index + 1)));
    }
    return Ok(List.generate(5, (index) => _object(index + 21)));
  }

  @override
  Future<Result<CelestialObject>> fetchById(String id) async =>
      Ok(_object(int.parse(id)));

  @override
  Future<Result<CelestialObject>> create(CelestialObject object) async =>
      Ok(object);

  @override
  Future<Result<CelestialObject>> update(CelestialObject object) async =>
      Ok(object);

  @override
  Future<Result<void>> delete(String id) async => const Ok(null);
}

void main() {
  test('search resets page and loadMore appends the next page', () async {
    final repository = _PagingRepository();
    final model = CelestialObjectsModel(repository);

    await model.load(search: 'Mars');

    expect(model.items.length, 20);
    expect(model.search, 'Mars');
    expect(model.hasMore, isTrue);
    expect(repository.page, 1);
    expect(repository.limit, 20);
    expect(repository.search, 'Mars');

    await model.loadMore();

    expect(model.items.length, 25);
    expect(model.search, 'Mars');
    expect(model.hasMore, isFalse);
    expect(repository.page, 2);
  });

  test('clear search preserves load and reload behavior', () async {
    final repository = _PagingRepository();
    final model = CelestialObjectsModel(repository);

    await model.load(search: 'Mars');
    await model.load(search: '');

    expect(model.search, '');
    expect(repository.search, '');
  });
}
