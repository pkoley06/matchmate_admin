import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_community_models.dart';

final adminCommunityApiProvider = Provider<AdminCommunityApi>(
  (ref) => AdminCommunityApi(ref.watch(apiDioProvider)),
);

class AdminCommunityApi {
  AdminCommunityApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/community';

  Future<AdminCommunityPostPage> listPosts({
    String? search,
    String? category,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_base/posts',
        queryParameters: {
          'page': page,
          'size': size,
          'search': ?search,
          'category': ?category,
        },
      );
      return AdminCommunityPostPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _dio.delete<void>('$_base/posts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminUserStatusPage> listStatuses({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_base/statuses',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      return AdminUserStatusPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteStatus(String id) async {
    try {
      await _dio.delete<void>('$_base/statuses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
