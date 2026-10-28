import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_questionnaire_repository.dart';
import '../domain/admin_questionnaire_models.dart';

class QuestionnaireState {
  const QuestionnaireState({
    this.overview,
    this.cleanlinessWeight = 2.0,
    this.sleepWeight = 1.5,
    this.guestWeight = 1.2,
    this.dietWeight = 1.0,
    this.smokingDealbreaker = true,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final AdminQuestionnaireOverview? overview;
  final double cleanlinessWeight;
  final double sleepWeight;
  final double guestWeight;
  final double dietWeight;
  final bool smokingDealbreaker;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  QuestionnaireState copyWith({
    AdminQuestionnaireOverview? overview,
    double? cleanlinessWeight,
    double? sleepWeight,
    double? guestWeight,
    double? dietWeight,
    bool? smokingDealbreaker,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) =>
      QuestionnaireState(
        overview: overview ?? this.overview,
        cleanlinessWeight: cleanlinessWeight ?? this.cleanlinessWeight,
        sleepWeight: sleepWeight ?? this.sleepWeight,
        guestWeight: guestWeight ?? this.guestWeight,
        dietWeight: dietWeight ?? this.dietWeight,
        smokingDealbreaker: smokingDealbreaker ?? this.smokingDealbreaker,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        successMessage: successMessage,
      );
}

final questionnaireControllerProvider =
    NotifierProvider<QuestionnaireController, QuestionnaireState>(
  QuestionnaireController.new,
);

class QuestionnaireController extends Notifier<QuestionnaireState> {
  AdminQuestionnaireRepository get _repository =>
      ref.read(adminQuestionnaireRepositoryProvider);

  @override
  QuestionnaireState build() {
    Future.microtask(loadOverview);
    return const QuestionnaireState(isLoading: true);
  }

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overview = await _repository.getOverview();
      state = state.copyWith(
        overview: overview,
        cleanlinessWeight: overview.currentWeights.cleanlinessWeight,
        sleepWeight: overview.currentWeights.sleepWeight,
        guestWeight: overview.currentWeights.guestWeight,
        dietWeight: overview.currentWeights.dietWeight,
        smokingDealbreaker: overview.currentWeights.smokingDealbreaker,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateCleanlinessWeight(double val) =>
      state = state.copyWith(cleanlinessWeight: val);

  void updateSleepWeight(double val) =>
      state = state.copyWith(sleepWeight: val);

  void updateGuestWeight(double val) =>
      state = state.copyWith(guestWeight: val);

  void updateDietWeight(double val) =>
      state = state.copyWith(dietWeight: val);

  void updateSmokingDealbreaker(bool val) =>
      state = state.copyWith(smokingDealbreaker: val);

  Future<bool> saveWeights() async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final updated = await _repository.updateWeights(
        QuestionnaireWeights(
          cleanlinessWeight: state.cleanlinessWeight,
          sleepWeight: state.sleepWeight,
          guestWeight: state.guestWeight,
          dietWeight: state.dietWeight,
          smokingDealbreaker: state.smokingDealbreaker,
        ),
      );

      state = state.copyWith(
        cleanlinessWeight: updated.cleanlinessWeight,
        sleepWeight: updated.sleepWeight,
        guestWeight: updated.guestWeight,
        dietWeight: updated.dietWeight,
        smokingDealbreaker: updated.smokingDealbreaker,
        isSaving: false,
        successMessage: 'Matching heuristic weights saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
