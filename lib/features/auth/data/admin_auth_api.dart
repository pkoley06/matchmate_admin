import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_session.dart';

final adminAuthApiProvider = Provider<AdminAuthApi>(
  (ref) => AdminAuthApi(ref.watch(publicDioProvider)),
);

class AdminAuthApi {
  AdminAuthApi(this._dio);

  final Dio _dio;

  /// POST /api/v1/admin/auth/login
  Future<AdminSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/auth/login',
        data: {'username': username, 'password': password},
      );
      return AdminSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
