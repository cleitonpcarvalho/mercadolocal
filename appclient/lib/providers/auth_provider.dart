import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> loadUser() async {
    _setLoading(true);
    try {
      final token = await StorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        _user = null;
        _isAuthenticated = false;
        return;
      }

      _user = await _authService.getMe();
      _isAuthenticated = true;
    } catch (_) {
      _user = null;
      _isAuthenticated = false;
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

  Future<void> register(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      _user = await _authService.register(payload);
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

  Future<void> updateUser(UserModel user) async {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void handleUnauthorized() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
