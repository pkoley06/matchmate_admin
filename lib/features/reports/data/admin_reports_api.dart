import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_report_models.dart';

final adminReportsApiProvider = Provider<AdminReportsApi>(
  (ref) => AdminReportsApi(ref.watch(apiDioProvider)),
);

class AdminReportsApi {
  AdminReportsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getReports({
    String? status,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (type != null && type.isNotEmpty) queryParams['type'] = type;

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/reports',
        queryParameters: queryParams,
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminReport> resolveReport(
    int reportId,
    AdminReportResolveRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/reports/$reportId/action',
        data: request.toJson(),
      );
      return AdminReport.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
