import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_dashboard_repository.dart';
import '../domain/admin_dashboard_models.dart';

/// Overview numbers. Kept alive: the sidebar's "Reports" badge reads it too.
/// Invalidate after anything that changes the counts (resolving a report…).
final dashboardStatsProvider = FutureProvider<AdminDashboardStats>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).getStats(),
);

/// Open reports for the sidebar badge; 0 until the numbers load.
final pendingReportsCountProvider = Provider<int>(
  (ref) => ref.watch(dashboardStatsProvider).value?.pendingReports ?? 0,
);
