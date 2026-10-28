import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'This server is taking too long. Please try again',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          "Cannot reach the server. Is the backend running?",
        );
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map &&
        data['message'] is String &&
        (data['message'] as String).isNotEmpty) {
      return ApiException(data['message'] as String, statusCode: status);
    }
    return ApiException(
      'Something went wrong (HTTP ${status ?? '?'})',
      statusCode: status,
    );
  }

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
