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
      data: <String, dynamic>{'email': email, 'password': password},
    );

    final Map<String, dynamic> body = ApiService.mapBody(response.data);
    final Map<String, dynamic> data = ApiService.dataFromResponse(body);

    final String access = (data['access'] ?? '').toString();
    final String refresh = (data['refresh'] ?? '').toString();

    if (access.isEmpty || refresh.isEmpty) {
      throw ApiException('Falha ao obter tokens de acesso.');
    }

    final UserModel user = UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map? ?? <String, dynamic>{}),
    );

    if (user.role != 'delivery_driver') {
      throw ApiException('Este app é exclusivo para entregadores');
    }

    await StorageService.saveTokens(accessToken: access, refreshToken: refresh);
    ApiService.setAccessToken(access);
    return user;
  }

  Future<void> logout() async {
    final String? refresh = await StorageService.readRefreshToken();

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await ApiService.instance.dio.post(
          ApiConstants.logout,
          data: <String, dynamic>{'refresh': refresh},
        );
      } on DioException {
        // Ignored because local cleanup is enough for logout.
      }
    }

    await StorageService.clearTokens();
    ApiService.setAccessToken(null);
  }

  Future<UserModel> getMe() async {
    final response = await ApiService.instance.dio.get(ApiConstants.me);
    final data = ApiService.dataFromResponse(response.data);
    final user = UserModel.fromJson(data);

    if (user.role != 'delivery_driver') {
      await StorageService.clearTokens();
      throw ApiException('Este app é exclusivo para entregadores');
    }

    return user;
  }
}
