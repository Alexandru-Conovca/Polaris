import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/observation_location.dart';
import 'result.dart';

class LocationService {
  static const _locationKey = 'observation_location';
  static const _positionTimeout = Duration(seconds: 15);

  Future<Result<ObservationLocation?>> loadSavedLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_locationKey);
      if (saved == null) {
        return const Ok(null);
      }
      final json = jsonDecode(saved) as Map<String, dynamic>;
      return Ok(ObservationLocation.fromJson(json));
    } on FormatException {
      return const Err('Сохранённые координаты повреждены. Обновите точку.');
    } on TypeError {
      return const Err('Сохранённые координаты повреждены. Обновите точку.');
    } on ArgumentError {
      return const Err('Сохранённые координаты повреждены. Обновите точку.');
    } on PlatformException {
      return const Err('Не удалось прочитать сохранённую точку наблюдения.');
    } on MissingPluginException {
      return const Err('Локальное хранилище недоступно на этом устройстве.');
    }
  }

  Future<Result<void>> saveLocation(ObservationLocation location) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _locationKey,
        jsonEncode(location.toJson()),
      );
      if (!saved) {
        return const Err('Не удалось сохранить точку наблюдения.');
      }
      return const Ok(null);
    } on PlatformException {
      return const Err('Не удалось сохранить точку наблюдения.');
    } on MissingPluginException {
      return const Err('Локальное хранилище недоступно на этом устройстве.');
    }
  }

  Future<Result<ObservationLocation>> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const Err('Включите службы геолокации на устройстве.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const Err('Доступ к геолокации отклонён.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const Err(
          'Доступ к геолокации запрещён. Разрешите его в настройках приложения.',
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const Err('Не удалось определить статус разрешения геолокации.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _positionTimeout),
      );
      return Ok(
        ObservationLocation.device(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
        ),
      );
    } on TimeoutException {
      return const Err(
        'Не удалось определить местоположение за отведённое время.',
      );
    } on LocationServiceDisabledException {
      return const Err('Включите службы геолокации на устройстве.');
    } on PermissionDeniedException {
      return const Err('Доступ к геолокации отклонён.');
    } on PlatformException {
      return const Err('Не удалось получить геопозицию устройства.');
    } on MissingPluginException {
      return const Err('Геолокация недоступна на этом устройстве.');
    }
  }

  Future<Result<void>> openAppSettings() async {
    try {
      final opened = await Geolocator.openAppSettings();
      if (!opened) {
        return const Err('Не удалось открыть настройки приложения.');
      }
      return const Ok(null);
    } on PlatformException {
      return const Err('Не удалось открыть настройки приложения.');
    } on MissingPluginException {
      return const Err('Настройки приложения недоступны на этом устройстве.');
    }
  }
}
