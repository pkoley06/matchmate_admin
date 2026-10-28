import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_reports_repository.dart';
import '../domain/admin_report_models.dart';

class ReportsState {
  const ReportsState({
    required this.reports,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.isLast,
    this.statusFilter,
    this.typeFilter,
    this.isLoading = false,
    this.error,
  });

  final List<AdminReport> reports;
  final int totalElements;
  final int totalPages;
  final int page;
  final bool isLast;
  final String? statusFilter;
  final String? typeFilter;
  final bool isLoading;
  final String? error;

  ReportsState copyWith({
    List<AdminReport>? reports,
    int? totalElements,
    int? totalPages,
    int? page,
    bool? isLast,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? typeFilter,
    bool clearTypeFilter = false,
    bool? isLoading,
    String? error,
  }) =>
      ReportsState(
        reports: reports ?? this.reports,
        totalElements: totalElements ?? this.totalElements,
        totalPages: totalPages ?? this.totalPages,
        page: page ?? this.page,
        isLast: isLast ?? this.isLast,
        statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
        typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportsState>(
  ReportsController.new,
);

class ReportsController extends Notifier<ReportsState> {
  AdminReportsRepository get _repo => ref.read(adminReportsRepositoryProvider);

  @override
  ReportsState build() {
    Future.microtask(() => loadReports());
    return const ReportsState(
      reports: [],
      totalElements: 0,
      totalPages: 0,
      page: 0,
      isLast: true,
      isLoading: true,
    );
  }

  Future<void> loadReports({int page = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getReports(
        status: state.statusFilter,
        type: state.typeFilter,
        page: page,
      );
      state = state.copyWith(
        reports: res.content,
        totalElements: res.totalElements,
        totalPages: res.totalPages,
        page: page,
        isLast: res.isLast,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadReports(page: 0);
  }

  Future<void> setTypeFilter(String? type) async {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
    );
    await loadReports(page: 0);
  }

  Future<bool> resolveReport(int reportId, String action, {String? notes}) async {
    try {
      await _repo.resolveReport(
        reportId,
        AdminReportResolveRequest(action: action, notes: notes),
      );
      await loadReports(page: state.page);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
