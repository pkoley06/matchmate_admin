import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_branding_models.dart';

final adminBrandingApiProvider = Provider<AdminBrandingApi>(
  (ref) => AdminBrandingApi(ref.watch(apiDioProvider)),
);

class AdminBrandingApi {
  AdminBrandingApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/branding
  Future<AdminBrandingConfig> getBranding() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/branding',
      );
      return AdminBrandingConfig.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /api/v1/admin/branding
  Future<AdminBrandingConfig> updateBranding(
    AdminBrandingUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/branding',
        data: request.toJson(),
      );
      return AdminBrandingConfig.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
