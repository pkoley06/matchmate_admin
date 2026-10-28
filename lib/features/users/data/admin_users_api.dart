import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_user_models.dart';

final adminUsersApiProvider = Provider<AdminUsersApi>(
  (ref) => AdminUsersApi(ref.watch(apiDioProvider)),
);

class AdminUsersApi {
  AdminUsersApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/users
  Future<AdminUserPage> getUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/users',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'size': size,
        },
      );
      return AdminUserPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/admin/users/{id}
  Future<AdminUserDetail> getUser(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/users/$id',
      );
      return AdminUserDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/admin/users
  Future<AdminUserDetail> createUser(AdminUserCreateRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/users',
        data: request.toJson(),
      );
      return AdminUserDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /api/v1/admin/users/{id}
  Future<AdminUserDetail> updateUser(
    int id,
    AdminUserUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/users/$id',
        data: request.toJson(),
      );
      return AdminUserDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/v1/admin/users/{id}/active
  Future<AdminUserDetail> setActive(int id, bool active) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/admin/users/$id/active',
        data: {'active': active},
      );
      return AdminUserDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/v1/admin/users/{id}/suspend
  Future<AdminUserDetail> setSuspended(int id, bool suspended, {String? reason}) async {
    try {
      final payload = <String, dynamic>{'suspended': suspended};
      if (reason != null) {
        payload['reason'] = reason;
      }
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/admin/users/$id/suspend',
        data: payload,
      );
      return AdminUserDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
