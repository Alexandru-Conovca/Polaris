import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/domain_models.dart';
import 'api_message.dart';
import 'result.dart';
import 'telescope_repository.dart';
import 'token_store.dart';

class HttpTelescopeRepository implements TelescopeRepository {
  HttpTelescopeRepository(this.baseUrl, this.tokens, {this.onUnauthorized});

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
  Future<Result<Telescope>> fetchById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/telescopes'), headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List;
      if (items.isEmpty) {
        final createResponse = await http
            .post(
              Uri.parse('$baseUrl/telescopes'),
              headers: await _headers(),
              body: jsonEncode({
                'name': 'My telescope',
                'aperture': 130,
                'focalLength': 900,
                'mountType': 'Equatorial',
              }),
            )
            .timeout(_timeout);

        if (createResponse.statusCode == 401) {
          return Err(await _sessionDied());
        }
        if (createResponse.statusCode != 201) {
          return Err(apiMessage(createResponse));
        }
        final created = jsonDecode(createResponse.body) as Map<String, dynamic>;
        return Ok(Telescope.fromJson(created));
      }

      final telescope = Telescope.fromJson(items.first as Map<String, dynamic>);
      return Ok(telescope);
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
  Future<Result<Telescope>> update(Telescope telescope) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/telescopes/${telescope.id}'),
            headers: await _headers(),
            body: jsonEncode(telescope.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return Err(await _sessionDied());
      }
      if (response.statusCode != 200) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(Telescope.fromJson(data));
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
