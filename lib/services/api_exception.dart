import 'package:dio/dio.dart';

/// A typed wrapper around API failures so the UI can show friendly messages.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDio(DioException err) {
    String message = 'Something went wrong. Please try again.';
    int? code = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'The request timed out. Check your connection and try again.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your network.';
    } else if (err.response?.data != null) {
      final data = err.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            data['detail']?.toString() ??
            message;
      }
    }

    return ApiException(message: message, statusCode: code, details: err);
  }

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => message;
}
