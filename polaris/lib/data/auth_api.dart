import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';
import '../models/domain_models.dart';

class AuthApi {
  AuthApi(this.baseUrl, this.tokens);

  final String baseUrl;
  final TokenStore tokens;

  static const _timeout = Duration(seconds: 8);

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

  Future<Result<void>> login(String email, String password) => _post(
    '/auth/login',
    {'email': email, 'password': password},
    isLogin: true,
  );

  Future<void> logout() => tokens.clear();

  Future<Result<User>> fetchMe() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/me'),
            headers: {'Authorization': 'Bearer ${await tokens.read() ?? ''}'},
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        await tokens.clear();
        return const Err('Сессия истекла');
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(
        User(
          name: data['name'] as String,
          email: data['email'] as String,
          level: 'Amateur Stargazer',
        ),
      );
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }

  Future<Result<void>> _post(
    String path,
    Map<String, Object?> body, {
    bool isLogin = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 401) {
          await tokens.clear();
        }
        return Err(apiMessage(response, isLogin: isLogin));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await tokens.save(data['token'] as String);
      return const Ok(null);
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
