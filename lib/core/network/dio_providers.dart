import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matchmate_admin/core/config/env.dart';
import 'package:matchmate_admin/core/network/auth_interceptor.dart';
import 'package:matchmate_admin/core/storage/admin_token_storage.dart';

import '../../features/auth/presentation/admin_auth_controller.dart';

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: Env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 20),
  contentType: Headers.jsonContentType,
);

/// Dio WITHOUT auth. Used only for POST /api/v1/admin/auth/login.
final publicDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

/// Dio WITH the admin Bearer JWT. Used for every /api/v1/admin/** endpoint.
final apiDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: ref.watch(adminTokenStorageProvider),
      onSessionExpired: () =>
          ref.read(adminAuthControllerProvider.notifier).signOut(),
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});
