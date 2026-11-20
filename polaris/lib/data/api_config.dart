import 'package:flutter/foundation.dart';

const _definedApiBase = String.fromEnvironment('API_BASE');

String get apiBase {
  if (_definedApiBase.isNotEmpty) {
    return _definedApiBase;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
