import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_dashboard_models.dart';
import 'admin_dashboard_api.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref.watch(adminDashboardApiProvider)),
);

class AdminDashboardRepository {
  AdminDashboardRepository(this._api);

  final AdminDashboardApi _api;

  Future<AdminDashboardStats> getStats() => _api.getStats();
}
