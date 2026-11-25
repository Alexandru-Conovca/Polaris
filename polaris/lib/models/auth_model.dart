import 'package:flutter/foundation.dart';

class AuthModel extends ChangeNotifier {
  AuthModel({required bool authenticated}) : _isAuthenticated = authenticated;

  bool _isAuthenticated;

  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    if (_isAuthenticated == value) {
      return;
    }
    _isAuthenticated = value;
    notifyListeners();
  }
}
