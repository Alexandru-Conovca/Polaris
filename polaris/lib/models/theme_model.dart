import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/result.dart';

class ThemeModel extends ChangeNotifier {
  static const _preferenceKey = 'red_night_mode';

  bool _isRedNightMode = false;
  String? _errorMessage;

  bool get isRedNightMode => _isRedNightMode;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _isRedNightMode = preferences.getBool(_preferenceKey) ?? false;
    } on PlatformException {
      _errorMessage = 'Не удалось загрузить настройку ночного режима.';
    } on MissingPluginException {
      _errorMessage = 'Хранилище настроек недоступно на этом устройстве.';
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> setRedNightMode(bool enabled) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_preferenceKey, enabled);
      if (!saved) {
        const message = 'Не удалось сохранить настройку ночного режима.';
        _errorMessage = message;
        notifyListeners();
        return const Err(message);
      }
      _isRedNightMode = enabled;
      _errorMessage = null;
      notifyListeners();
      return const Ok(null);
    } on PlatformException {
      const message = 'Не удалось сохранить настройку ночного режима.';
      _errorMessage = message;
      notifyListeners();
      return const Err(message);
    } on MissingPluginException {
      const message = 'Хранилище настроек недоступно на этом устройстве.';
      _errorMessage = message;
      notifyListeners();
      return const Err(message);
    }
  }
}
