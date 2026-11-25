import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/data/celestial_object.dart';
import 'package:polaris/data/celestial_object_repository.dart';
import 'package:polaris/data/result.dart';
import 'package:polaris/main.dart';
import 'package:polaris/models/auth_model.dart';
import 'package:polaris/models/celestial_objects_model.dart';
import 'package:polaris/models/theme_model.dart';
import 'package:polaris/models/weather_model.dart';
import 'package:polaris/router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Polaris opens in guest mode without blocking registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthModel(authenticated: false),
          ),
          ChangeNotifierProvider(create: (_) => ThemeModel()),
          ChangeNotifierProvider(create: (_) => WeatherModel()),
          ChangeNotifierProvider(
            create: (_) => CelestialObjectsModel(_EmptyCatalogRepository()),
          ),
        ],
        child: Polaris(routerConfig: createRouter()),
      ),
    );

    expect(find.text('Polaris'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Каталог доступен после входа'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsNothing);
    expect(find.text('34'), findsNothing);
    expect(find.text('Current quest'), findsNothing);
    expect(find.text('Recent activity'), findsNothing);
    expect(find.text('Настройки телескопа'), findsNothing);
  });
}

class _EmptyCatalogRepository implements CelestialObjectRepository {
  @override
  Future<Result<List<CelestialObject>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async => const Ok([]);

  @override
  Future<Result<CelestialObject>> fetchById(String id) async =>
      const Err('Not found');

  @override
  Future<Result<CelestialObject>> create(CelestialObject object) async =>
      const Err('Not available');

  @override
  Future<Result<CelestialObject>> update(CelestialObject object) async =>
      const Err('Not available');

  @override
  Future<Result<void>> delete(String id) async => const Err('Not available');
}
