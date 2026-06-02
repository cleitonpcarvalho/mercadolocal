import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
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
          String? token = _accessTokenCache;
          if (token == null || token.isEmpty) {
            token = await StorageService.readAccessToken();
            if (token != null && token.isNotEmpty) {
              _accessTokenCache = token;
            }
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final String message = _extractErrorMessage(error);

          if (error.response?.statusCode == 401) {
            await StorageService.clearTokens();
            _accessTokenCache = null;
            _onUnauthorized?.call();
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
  static String? _accessTokenCache;
  static void Function()? _onUnauthorized;

  Dio get dio => _dio;

  static void setUnauthorizedHandler(void Function() callback) {
    _onUnauthorized = callback;
  }

  static Future<void> hydrateAccessToken() async {
    final String? token = await StorageService.readAccessToken();
    _accessTokenCache = token;
  }

  static void setAccessToken(String? token) {
    _accessTokenCache = token;
  }

  String _extractErrorMessage(DioException error) {
    final dynamic responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final dynamic data = responseData['data'];
      if (data is Map<String, dynamic> && data.isNotEmpty) {
        final dynamic firstValue = data.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) {
          return firstValue.toString();
        }
      }
    }

    return error.message ?? 'Falha ao comunicar com o servidor.';
  }

  static Map<String, dynamic> mapBody(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static List<dynamic> listFromResponse(dynamic body) {
    final Map<String, dynamic> mapped = mapBody(body);
    final dynamic data = mapped['data'];

    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final dynamic results = data['results'];
      if (results is List) return results;
    }

    return <dynamic>[];
  }

  static Map<String, dynamic> dataFromResponse(dynamic body) {
    final Map<String, dynamic> mapped = mapBody(body);
    final dynamic data = mapped['data'];

    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    return <String, dynamic>{};
  }
}
