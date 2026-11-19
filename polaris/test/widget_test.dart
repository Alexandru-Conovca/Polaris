import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/main.dart';
import 'package:polaris/router.dart';

void main() {
  testWidgets('Polaris starts at authentication screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Polaris(routerConfig: createRouter(loggedIn: false)),
    );

    expect(find.text('Welcome to Polaris'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
