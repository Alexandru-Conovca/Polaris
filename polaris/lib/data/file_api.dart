import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

class FileApi {
  FileApi(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 20);
  static const _maxUploadBytes = 5 * 1024 * 1024;

  Future<Result<String>> upload(
    String path, {
    List<int>? bytes,
    String? filename,
  }) async {
    if ((bytes == null && path.isEmpty) ||
        (bytes != null && bytes.length > _maxUploadBytes) ||
        (bytes == null && File(path).lengthSync() > _maxUploadBytes)) {
      return const Err('Файл больше 5 МБ');
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/files'),
      );
      request.headers['Authorization'] = 'Bearer ${await tokens.read() ?? ''}';

      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename ?? 'photo.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', path, filename: filename),
        );
      }

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401) {
        await tokens.clear();
        onUnauthorized?.call();
        return const Err('Сессия истекла — войдите снова');
      }
      if (response.statusCode != 201) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(data['url'] as String);
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FileSystemException {
      return const Err('Не удалось прочитать выбранный файл');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
