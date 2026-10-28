import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_questionnaire_models.dart';
import 'admin_questionnaire_api.dart';

final adminQuestionnaireRepositoryProvider =
    Provider<AdminQuestionnaireRepository>(
  (ref) => AdminQuestionnaireRepository(ref.watch(adminQuestionnaireApiProvider)),
);

class AdminQuestionnaireRepository {
  AdminQuestionnaireRepository(this._api);

  final AdminQuestionnaireApi _api;

  Future<AdminQuestionnaireOverview> getOverview() => _api.getOverview();

  Future<QuestionnaireWeights> updateWeights(QuestionnaireWeights weights) =>
      _api.updateWeights(weights);
}
