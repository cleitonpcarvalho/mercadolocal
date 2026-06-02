import 'package:dio/dio.dart';

import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  const AuthService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.instance.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final body = ApiService.mapBody(response.data);
    final data = ApiService.dataFromResponse(body);

    final access = (data['access'] ?? '').toString();
    final refresh = (data['refresh'] ?? '').toString();

    if (access.isEmpty || refresh.isEmpty) {
      throw ApiException('Falha ao obter tokens de acesso');
    }

    await StorageService.saveTokens(accessToken: access, refreshToken: refresh);

    return UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map? ?? <String, dynamic>{}),
    );
  }

  Future<UserModel> register(Map<String, dynamic> payload) async {
    final response = await ApiService.instance.dio.post(
      ApiConstants.register,
      data: payload,
    );

    final body = ApiService.mapBody(response.data);
    final data = ApiService.dataFromResponse(body);

    final access = (data['access'] ?? '').toString();
    final refresh = (data['refresh'] ?? '').toString();

    if (access.isEmpty || refresh.isEmpty) {
      throw ApiException('Falha ao obter tokens de acesso');
    }

    await StorageService.saveTokens(accessToken: access, refreshToken: refresh);

    return UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map? ?? <String, dynamic>{}),
    );
  }

  Future<void> logout() async {
    final refresh = await StorageService.readRefreshToken();

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await ApiService.instance.dio.post(
          ApiConstants.logout,
          data: {'refresh': refresh},
        );
      } on DioException {
        // Token may be expired; local cleanup still applies.
      }
    }

    await StorageService.clearTokens();
  }

  Future<UserModel> getMe() async {
    final response = await ApiService.instance.dio.get(ApiConstants.me);
    final data = ApiService.dataFromResponse(response.data);
    return UserModel.fromJson(data);
  }

  Future<void> refreshToken() async {
    final refresh = await StorageService.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw ApiException('Sessao expirada');
    }

    final response = await ApiService.instance.dio.post(
      ApiConstants.refreshToken,
      data: {'refresh': refresh},
    );

    final body = ApiService.mapBody(response.data);
    final data = ApiService.dataFromResponse(body);

    final access = (data['access'] ?? '').toString();
    if (access.isEmpty) {
      throw ApiException('Falha ao renovar token');
    }

    await StorageService.saveAccessToken(access);
  }
}
