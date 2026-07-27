import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio that knows the base URL and how to attach the
/// Bearer token. Other services use [ApiClient.dio] to make requests.
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  static ApiClient? _instance;

  /// Singleton accessor. The token provider is optional; auth service
  /// updates it via [setTokenProvider] after the secure storage is ready.
  static ApiClient instance() {
    if (_instance != null) return _instance!;
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    _instance = ApiClient._(dio);
    return _instance!;
  }

  String? Function()? _tokenProvider;
  String? _cachedToken;

  /// Registers a callback that returns the current JWT, if any.
  void setTokenProvider(String? Function() provider) {
    _tokenProvider = provider;
  }

  /// Returns the currently stored JWT (cached after first read).
  String? currentToken() {
    if (_cachedToken != null) return _cachedToken;
    if (_tokenProvider != null) {
      final tokenFunc = _tokenProvider!;
_cachedToken = tokenFunc();
    }
    
    return _cachedToken;
  }

  /// Updates the cached token and refreshes the auth header.
  void updateToken(String? token) {
    _cachedToken = token;
    _dio.options.headers['Authorization'] =
        token != null ? 'Bearer $token' : null;
  }

  Dio get dio => _dio;

  /// Convenience: performs a GET, throwing [ApiException] on failure.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _options(authenticated),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Convenience: performs a POST, throwing [ApiException] on failure.
  Future<Response<T>> post<T>(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: body,
        options: _options(authenticated),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Options _options(bool authenticated) {
    if (!authenticated) return Options();
    final token = currentToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }
}
