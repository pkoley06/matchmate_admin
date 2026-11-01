import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_comment_models.dart';

final adminCommentsApiProvider = Provider<AdminCommentsApi>(
  (ref) => AdminCommentsApi(ref.watch(apiDioProvider)),
);

/// `/api/v1/admin/comments` — the comment moderation log.
class AdminCommentsApi {
  AdminCommentsApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/comments';

  Future<AdminCommentPage> list({
    String? search,
    String? listingId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _base,
        queryParameters: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
          'listingId': ?listingId,
        },
      );
      return AdminCommentPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminComment> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_base/$id');
      return AdminComment.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('$_base/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
