import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'navigation_service.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final message = _extractErrorMessage(error);

          if (error.response?.statusCode == 401) {
            await StorageService.clearTokens();
            _onUnauthorized?.call();
            NavigationService.goToLogin();
          }

          handler.next(
            error.copyWith(error: ApiException(message), message: message),
          );
        },
      ),
    );
  }

  static final ApiService instance = ApiService._internal();

  late final Dio _dio;
  static void Function()? _onUnauthorized;

  Dio get dio => _dio;

  static void setUnauthorizedHandler(void Function() callback) {
    _onUnauthorized = callback;
  }

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final data = responseData['data'];
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        final firstValue = data.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) {
          return firstValue.toString();
        }
      }
    }

    return error.message ?? 'Falha na comunicacao com servidor';
  }

  static Map<String, dynamic> mapBody(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static List<dynamic> listFromResponse(dynamic body) {
    final mapped = mapBody(body);
    final data = mapped['data'];

    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) return results;
    }
    return <dynamic>[];
  }

  static Map<String, dynamic> dataFromResponse(dynamic body) {
    final mapped = mapBody(body);
    final data = mapped['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
