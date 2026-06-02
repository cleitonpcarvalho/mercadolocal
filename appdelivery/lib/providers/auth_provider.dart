import 'package:flutter/foundation.dart';

import '../core/services/api_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _setLoading(true);
    try {
      final String? token = await StorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        ApiService.setAccessToken(null);
        _isAuthenticated = false;
        _user = null;
        return;
      }

      ApiService.setAccessToken(token);
      _user = await _authService.getMe();
      _isAuthenticated = true;
    } catch (_) {
      ApiService.setAccessToken(null);
      _isAuthenticated = false;
      _user = null;
      await StorageService.clearTokens();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email: email, password: password);
      _isAuthenticated = true;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
