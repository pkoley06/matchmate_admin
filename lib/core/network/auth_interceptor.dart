import 'package:dio/dio.dart';
import 'package:matchmate_admin/core/storage/admin_token_storage.dart';

/// Adds an `Authorization: Bearer` header (the admin JWT) to every request. Unlike the mobile
/// app's interceptor there is no refresh token - admin tokens are long-lived
/// enough (24h) that a 401 just means "log in again".
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._onSessionExpired,
  });

  final AdminTokenStorage _tokenStorage;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.clear();
      _onSessionExpired();
    }
    handler.next(err);
  }
}
