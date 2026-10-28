import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_branding_repository.dart';
import '../domain/admin_branding_models.dart';

class BrandingState {
  const BrandingState({
    this.config,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final AdminBrandingConfig? config;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  BrandingState copyWith({
    AdminBrandingConfig? config,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) =>
      BrandingState(
        config: config ?? this.config,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        successMessage: successMessage,
      );
}

final brandingControllerProvider =
    NotifierProvider<BrandingController, BrandingState>(BrandingController.new);

class BrandingController extends Notifier<BrandingState> {
  AdminBrandingRepository get _repository => ref.read(adminBrandingRepositoryProvider);

  @override
  BrandingState build() {
    Future.microtask(loadBranding);
    return const BrandingState(isLoading: true);
  }

  Future<void> loadBranding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final config = await _repository.getBranding();
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateBranding(AdminBrandingUpdateRequest request) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final updated = await _repository.updateBranding(request);
      state = state.copyWith(
        config: updated,
        isSaving: false,
        successMessage: 'Branding settings saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
