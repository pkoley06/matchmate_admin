import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_community_models.dart';

final adminCommunityApiProvider = Provider<AdminCommunityApi>(
  (ref) => AdminCommunityApi(ref.watch(apiDioProvider)),
);

/// Post list filters understood by GET /admin/community/posts?state=.
enum PostFilter { all, active, hidden, pinned, reported }

/// Status list filters understood by GET /admin/community/statuses?state=.
enum StatusFilter { live, expired, reported, all }

/// /api/v1/admin/community: posts, comments and statuses.
class AdminCommunityApi {
  AdminCommunityApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/community';

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Posts ────────────────────────────────────────────────────────────────

  Future<Paged<AdminCommunityPost>> listPosts({
    String? search,
    String? category,
    PostFilter filter = PostFilter.all,
    String? authorId,
    int page = 0,
    int size = 20,
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/posts',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
        'category': ?category,
        'state': filter.name.toUpperCase(),
        'authorId': ?authorId,
      },
    );
    return Paged.fromJson(res.data!, AdminCommunityPost.fromJson);
  });

  Future<AdminPostDetail> getPost(String id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('$_base/posts/$id');
    return AdminPostDetail.fromJson(res.data!);
  });

  Future<AdminCommunityPost> setPinned(String id, bool pinned) =>
      _call(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '$_base/posts/$id/pin',
          data: {'pinned': pinned},
        );
        return AdminCommunityPost.fromJson(res.data!);
      });

  /// 'ARCHIVED' hides the post in the app; 'ACTIVE' brings it back.
  Future<AdminCommunityPost> setStatus(String id, String status) =>
      _call(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '$_base/posts/$id/status',
          data: {'status': status},
        );
        return AdminCommunityPost.fromJson(res.data!);
      });

  Future<AdminCommunityPost> removePhoto(String id, String url) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '$_base/posts/$id/photos/remove',
          data: {'url': url},
        );
        return AdminCommunityPost.fromJson(res.data!);
      });

  Future<void> dismissPostReports(String id) =>
      _call(() => _dio.post<void>('$_base/posts/$id/reports/dismiss'));

  // ── Comments ─────────────────────────────────────────────────────────────

  Future<Paged<AdminCommunityComment>> listComments({
    String? search,
    bool reportedOnly = false,
    int page = 0,
    int size = 20,
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/comments',
      queryParameters: {
        'page': page,
        'size': size,
        if (search != null && search.isNotEmpty) 'search': search,
        'reportedOnly': reportedOnly,
      },
    );
    return Paged.fromJson(res.data!, AdminCommunityComment.fromJson);
  });

  /// Deletes the comment and every reply under it.
  Future<void> deleteComment(String id) =>
      _call(() => _dio.delete<void>('$_base/comments/$id'));

  Future<void> dismissCommentReports(String id) =>
      _call(() => _dio.post<void>('$_base/comments/$id/reports/dismiss'));

  // ── Statuses ─────────────────────────────────────────────────────────────

  Future<Paged<AdminUserStatus>> listStatuses({
    StatusFilter filter = StatusFilter.live,
    String? search,
    String? userId,
    int page = 0,
    int size = 24,
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/statuses',
      queryParameters: {
        'page': page,
        'size': size,
        'state': filter.name.toUpperCase(),
        if (search != null && search.isNotEmpty) 'search': search,
        'userId': ?userId,
      },
    );
    return Paged.fromJson(res.data!, AdminUserStatus.fromJson);
  });

  Future<AdminStatusDetail> getStatus(String id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>('$_base/statuses/$id');
    return AdminStatusDetail.fromJson(res.data!);
  });

  Future<void> deleteStatus(String id) =>
      _call(() => _dio.delete<void>('$_base/statuses/$id'));

  Future<void> dismissStatusReports(String id) =>
      _call(() => _dio.post<void>('$_base/statuses/$id/reports/dismiss'));
}
