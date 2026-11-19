import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'celestial_object.dart';
import 'celestial_object_repository.dart';
import 'result.dart';
import 'token_store.dart';

class HttpCelestialObjectRepository implements CelestialObjectRepository {
  HttpCelestialObjectRepository(
    this.baseUrl,
    this.tokens, {
    this.onUnauthorized,
  });

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 8);

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}',
  };

  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }

  @override
  Future<Result<List<CelestialObject>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/celestial-objects').replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List;
      return Ok(
        items
            .map(
              (item) => CelestialObject.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
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

  @override
  Future<Result<CelestialObject>> fetchById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/celestial-objects/$id'),
            headers: await _headers(),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(CelestialObject.fromJson(data));
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

  @override
  Future<Result<CelestialObject>> create(CelestialObject object) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/celestial-objects'),
            headers: await _headers(),
            body: jsonEncode(object.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 201) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(CelestialObject.fromJson(data));
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

  @override
  Future<Result<CelestialObject>> update(CelestialObject object) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/celestial-objects/${object.id}'),
            headers: await _headers(),
            body: jsonEncode(object.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(CelestialObject.fromJson(data));
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

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/celestial-objects/$id'),
            headers: await _headers(),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 204) {
        return Err(apiMessage(response));
      }

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
