import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_dashboard_models.dart';

final adminDashboardApiProvider = Provider<AdminDashboardApi>(
  (ref) => AdminDashboardApi(ref.watch(apiDioProvider)),
);

class AdminDashboardApi {
  AdminDashboardApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/dashboard/stats
  Future<AdminDashboardStats> getStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/dashboard/stats',
      );
      return AdminDashboardStats.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
