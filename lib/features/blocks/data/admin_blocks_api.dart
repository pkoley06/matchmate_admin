import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';

/// One row of GET /api/v1/admin/blocks.
class AdminBlock {
  const AdminBlock({
    required this.blockerId,
    required this.blockerName,
    required this.blockedId,
    required this.blockedName,
    required this.blockedUserTotalBlocks,
    required this.createdAt,
  });

  final String blockerId;
  final String blockerName;
  final String blockedId;
  final String blockedName;

  /// How many people in total have blocked [blockedId] — an abuse signal.
  final int blockedUserTotalBlocks;
  final DateTime? createdAt;

  factory AdminBlock.fromJson(Map<String, dynamic> json) => AdminBlock(
        blockerId: json['blockerId'] as String,
        blockerName: (json['blockerName'] as String?) ?? 'Unknown',
        blockedId: json['blockedId'] as String,
        blockedName: (json['blockedName'] as String?) ?? 'Unknown',
        blockedUserTotalBlocks:
            (json['blockedUserTotalBlocks'] as num?)?.toInt() ?? 1,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

final adminBlocksApiProvider = Provider<AdminBlocksApi>(
  (ref) => AdminBlocksApi(ref.watch(apiDioProvider)),
);

class AdminBlocksApi {
  AdminBlocksApi(this._dio);

  final Dio _dio;

  Future<({List<AdminBlock> content, int totalElements, int totalPages})> list({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/blocks',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data!;
      final content = (data['content'] as List<dynamic>? ?? const [])
          .map((e) => AdminBlock.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        content: content,
        totalElements: (data['totalElements'] as num?)?.toInt() ?? content.length,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(String blockerId, String blockedId) async {
    try {
      await _dio.delete<void>('/api/v1/admin/blocks/$blockerId/$blockedId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
