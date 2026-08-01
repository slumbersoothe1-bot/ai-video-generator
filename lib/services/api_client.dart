import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio with global interceptors that automatically
/// attach the Supabase `apikey` header and the user's `Authorization:
/// Bearer` token to every request — including sign-up and sign-in,
/// which are unauthenticated but still require the apikey.
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
    _instance!._setupInterceptors();
    return _instance!;
  }

  String? Function()? _tokenProvider;
  String? _cachedToken;

  void setTokenProvider(String? Function() provider) {
    _tokenProvider = provider;
  }

  String? currentToken() {
    if (_cachedToken != null) return _cachedToken;
    if (_tokenProvider != null) {
      _cachedToken = _tokenProvider!();
    }
    return _cachedToken;
  }

  void updateToken(String? token) {
    _cachedToken = token;
  }

  /// Installs the global interceptor that attaches security headers
  /// to every outgoing request. This is the single source of truth for
  /// authentication headers — no call site needs to manage headers.
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 1. Always attach the Supabase anon key. Without this the
          //    gateway returns "Missing authorization header" on every
          //    request, including login and register.
          options.headers['apikey'] = AppConfig.supabaseAnonKey;

          // 2. Attach the user's JWT as a Bearer token when available.
          //    For login/register the token is null, which is correct —
          //    the apikey alone is sufficient for those endpoints.
          final token = currentToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (e, handler) {
          // Convert Dio errors into typed ApiExceptions so the UI can
          // show friendly messages.
          handler.reject(ApiException.fromDio(e));
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Convenience: performs a GET, throwing [ApiException] on failure.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Convenience: performs a POST, throwing [ApiException] on failure.
  Future<Response<T>> post<T>(
    String path, {
    Object? body,
  }) async {
    try {
      return await _dio.post<T>(path, data: body);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
