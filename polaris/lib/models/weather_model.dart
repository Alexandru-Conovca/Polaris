import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/location_service.dart';
import '../data/result.dart';
import '../data/weather_service.dart';
import 'observation_location.dart';
import 'weather_snapshot.dart';

class WeatherModel extends ChangeNotifier {
  WeatherModel({
    LocationService? locationService,
    WeatherService? weatherService,
  }) : _locationService = locationService ?? LocationService(),
       _weatherService = weatherService ?? WeatherService();

  static const _cacheKey = 'weather_snapshot_v1';

  final LocationService _locationService;
  final WeatherService _weatherService;

  ObservationLocation? _location;
  WeatherSnapshot? _weather;
  bool _isLoading = false;
  bool _isRefreshingLocation = false;
  bool _isRefreshingWeather = false;
  String? _locationErrorMessage;
  String? _weatherErrorMessage;

  ObservationLocation? get location => _location;
  WeatherSnapshot? get weather => _weather;
  WeatherSnapshot? get currentWeather {
    final location = _location;
    final weather = _weather;
    if (location == null ||
        weather == null ||
        !weather.matchesLocation(location.latitude, location.longitude)) {
      return null;
    }
    return weather;
  }

  bool get isLoading => _isLoading;
  bool get isRefreshingLocation => _isRefreshingLocation;
  bool get isRefreshingWeather => _isRefreshingWeather;
  String? get locationErrorMessage => _locationErrorMessage;
  String? get weatherErrorMessage => _weatherErrorMessage;

  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final locationResult = await _locationService.loadSavedLocation();
      switch (locationResult) {
        case Ok(value: final location):
          _location = location;
        case Err(msg: final message):
          _locationErrorMessage = message;
      }

      final weatherResult = await _loadCachedWeather();
      switch (weatherResult) {
        case Ok(value: final weather):
          _weather = weather;
        case Err(msg: final message):
          _weatherErrorMessage = message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    if (_location != null) {
      unawaited(refreshWeather());
    }
  }

  Future<Result<void>> refreshLocation() async {
    if (_isRefreshingLocation) {
      return const Err('Геопозиция уже обновляется.');
    }
    _isRefreshingLocation = true;
    _locationErrorMessage = null;
    notifyListeners();
    try {
      final result = await _locationService.getCurrentLocation();
      switch (result) {
        case Ok(value: final location):
          _location = location;
          final saveResult = await _locationService.saveLocation(location);
          switch (saveResult) {
            case Ok():
              _locationErrorMessage = null;
              return const Ok(null);
            case Err(msg: final message):
              _locationErrorMessage = message;
              return Err(message);
          }
        case Err(msg: final message):
          _locationErrorMessage = message;
          return Err(message);
      }
    } finally {
      _isRefreshingLocation = false;
      notifyListeners();
    }
  }

  Future<Result<void>> saveLocation(ObservationLocation location) async {
    _location = location;
    _locationErrorMessage = null;
    notifyListeners();
    final result = await _locationService.saveLocation(location);
    switch (result) {
      case Ok():
        return const Ok(null);
      case Err(msg: final message):
        _locationErrorMessage = message;
        notifyListeners();
        return Err(message);
    }
  }

  Future<Result<WeatherSnapshot>> refreshWeather() async {
    final location = _location;
    if (location == null) {
      const error = 'Сначала задайте точку наблюдения.';
      _weatherErrorMessage = error;
      notifyListeners();
      return const Err(error);
    }
    if (_isRefreshingWeather) {
      return const Err('Погода уже обновляется.');
    }

    _isRefreshingWeather = true;
    _weatherErrorMessage = null;
    notifyListeners();
    try {
      final result = await _weatherService.fetch(location);
      switch (result) {
        case Ok(value: final weather):
          _weather = weather;
          final cacheResult = await _saveCachedWeather(weather);
          if (cacheResult case Err(msg: final message)) {
            _weatherErrorMessage = message;
          }
          return Ok(weather);
        case Err(msg: final message):
          _weatherErrorMessage = message;
          return Err(message);
      }
    } finally {
      _isRefreshingWeather = false;
      notifyListeners();
    }
  }

  Future<Result<void>> openLocationSettings() =>
      _locationService.openAppSettings();

  Future<Result<WeatherSnapshot?>> _loadCachedWeather() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_cacheKey);
      if (saved == null) {
        return const Ok(null);
      }
      final json = jsonDecode(saved) as Map<String, dynamic>;
      return Ok(WeatherSnapshot.fromJson(json));
    } on FormatException {
      return const Err('Локальный кэш погоды повреждён.');
    } on TypeError {
      return const Err('Локальный кэш погоды повреждён.');
    } on ArgumentError {
      return const Err('Локальный кэш погоды повреждён.');
    } on PlatformException {
      return const Err('Не удалось прочитать локальный кэш погоды.');
    } on MissingPluginException {
      return const Err('Локальное хранилище недоступно на этом устройстве.');
    }
  }

  Future<Result<void>> _saveCachedWeather(WeatherSnapshot weather) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _cacheKey,
        jsonEncode(weather.toJson()),
      );
      if (!saved) {
        return const Err('Погода обновлена, но кэш сохранить не удалось.');
      }
      return const Ok(null);
    } on PlatformException {
      return const Err('Погода обновлена, но кэш сохранить не удалось.');
    } on MissingPluginException {
      return const Err('Локальное хранилище недоступно на этом устройстве.');
    }
  }
}
