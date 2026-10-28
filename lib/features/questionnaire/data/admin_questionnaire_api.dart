import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_providers.dart';
import '../domain/admin_questionnaire_models.dart';

final adminQuestionnaireApiProvider = Provider<AdminQuestionnaireApi>(
  (ref) => AdminQuestionnaireApi(ref.watch(apiDioProvider)),
);

class AdminQuestionnaireApi {
  AdminQuestionnaireApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/admin/questionnaire
  Future<AdminQuestionnaireOverview> getOverview() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/questionnaire',
      );
      return AdminQuestionnaireOverview.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /api/v1/admin/questionnaire/weights
  Future<QuestionnaireWeights> updateWeights(
    QuestionnaireWeights weights,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/questionnaire/weights',
        data: weights.toJson(),
      );
      return QuestionnaireWeights.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
