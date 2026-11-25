import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/models/weather_model.dart';
import 'package:polaris/widgets/observation_conditions_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('details toggle and collapse after navigating away', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ListView(
              children: [
                const ObservationConditionsCard(),
                TextButton(
                  onPressed: () => context.push('/other'),
                  child: const Text('Other tab'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WeatherModel(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Место наблюдения'), findsNothing);
    await tester.tap(find.text('Точка и условия наблюдения'));
    await tester.pumpAndSettle();
    expect(find.text('Место наблюдения'), findsOneWidget);

    await tester.tap(find.text('Точка и условия наблюдения'));
    await tester.pumpAndSettle();
    expect(find.text('Место наблюдения'), findsNothing);

    await tester.tap(find.text('Точка и условия наблюдения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Место наблюдения'), findsNothing);
    router.dispose();
  });
}
