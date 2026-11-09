import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_announcement_models.dart';

final adminAnnouncementsApiProvider = Provider<AdminAnnouncementsApi>(
  (ref) => AdminAnnouncementsApi(ref.watch(apiDioProvider)),
);

class AdminAnnouncementsApi {
  AdminAnnouncementsApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/announcements
  Future<List<AdminAnnouncement>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/admin/announcements',
      );
      return (response.data ?? [])
          .map((e) => AdminAnnouncement.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/admin/announcements/broadcast
  Future<AdminAnnouncement> broadcast(
    AdminAnnouncementBroadcastRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/announcements/broadcast',
        data: request.toJson(),
      );
      return AdminAnnouncement.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
