import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_branding_models.dart';
import 'admin_branding_api.dart';

final adminBrandingRepositoryProvider = Provider<AdminBrandingRepository>(
  (ref) => AdminBrandingRepository(ref.watch(adminBrandingApiProvider)),
);

class AdminBrandingRepository {
  AdminBrandingRepository(this._api);

  final AdminBrandingApi _api;

  Future<AdminBrandingConfig> getBranding() => _api.getBranding();

  Future<AdminBrandingConfig> updateBranding(
    AdminBrandingUpdateRequest request,
  ) => _api.updateBranding(request);
}
