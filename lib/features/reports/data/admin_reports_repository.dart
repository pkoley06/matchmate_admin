import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_report_models.dart';
import 'admin_reports_api.dart';

final adminReportsRepositoryProvider = Provider<AdminReportsRepository>(
  (ref) => AdminReportsRepository(ref.watch(adminReportsApiProvider)),
);

class AdminReportsRepository {
  AdminReportsRepository(this._api);

  final AdminReportsApi _api;

  Future<({List<AdminReport> content, int totalElements, int totalPages, bool isLast})>
      getReports({String? status, String? type, int page = 0, int size = 20}) async {
    final data = await _api.getReports(status: status, type: type, page: page, size: size);
    final rawList = (data['content'] as List<dynamic>? ?? const []);
    final content = rawList
        .map((e) => AdminReport.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      content: content,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? content.length,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      isLast: data['isLast'] as bool? ?? true,
    );
  }

  Future<AdminReport> resolveReport(
    int reportId,
    AdminReportResolveRequest request,
  ) {
    return _api.resolveReport(reportId, request);
  }
}
