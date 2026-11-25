import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/models/theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and restores red night mode', () async {
    SharedPreferences.setMockInitialValues({});
    final theme = ThemeModel();

    await theme.setRedNightMode(true);
    final restored = ThemeModel();
    await restored.load();

    expect(restored.isRedNightMode, isTrue);
  });
}
