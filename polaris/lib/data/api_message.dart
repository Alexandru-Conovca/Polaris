import 'dart:convert';

import 'package:http/http.dart' as http;

String apiMessage(http.Response response, {bool isLogin = false}) {
  try {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final error = data['error'] as Map<String, dynamic>;
    final code = error['code'] as String;

    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' when isLogin => 'Неверный email или пароль',
      'UNAUTHORIZED' => 'Сессия истекла',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера (${response.statusCode})',
    };
  } on FormatException catch (_) {
    return 'Ошибка сервера (${response.statusCode})';
  } on TypeError catch (_) {
    return 'Ошибка сервера (${response.statusCode})';
  }
}
