import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_room_models.dart';

final adminRoomsApiProvider = Provider<AdminRoomsApi>(
  (ref) => AdminRoomsApi(ref.watch(apiDioProvider)),
);

class AdminRoomsApi {
  AdminRoomsApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/listings
  Future<AdminRoomPage> getRooms({
    String? search,
    bool? available,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (available != null) {
        queryParams['available'] = available;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/listings',
        queryParameters: queryParams,
      );
      return AdminRoomPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/v1/admin/listings/{id}
  Future<AdminRoomDetail> getRoom(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/listings/$id',
      );
      return AdminRoomDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/v1/admin/listings
  Future<AdminRoomDetail> createRoom(AdminRoomCreateRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/listings',
        data: request.toJson(),
      );
      return AdminRoomDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /api/v1/admin/listings/{id}
  Future<AdminRoomDetail> updateRoom(
    int id,
    AdminRoomUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/listings/$id',
        data: request.toJson(),
      );
      return AdminRoomDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/v1/admin/listings/{id}/available
  Future<AdminRoomDetail> setAvailable(int id, bool available) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/admin/listings/$id/available',
        data: {'available': available},
      );
      return AdminRoomDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /api/v1/admin/listings/{id}
  Future<void> deleteRoom(int id) async {
    try {
      await _dio.delete('/api/v1/admin/listings/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
