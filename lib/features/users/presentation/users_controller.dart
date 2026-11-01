import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_users_repository.dart';
import '../domain/admin_user_models.dart';

class UsersState {
  const UsersState({
    required this.pageData,
    this.searchQuery = '',
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  final AdminUserPage? pageData;
  final String searchQuery;
  final int currentPage;
  final bool isLoading;
  final String? error;

  UsersState copyWith({
    AdminUserPage? pageData,
    String? searchQuery,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) =>
      UsersState(
        pageData: pageData ?? this.pageData,
        searchQuery: searchQuery ?? this.searchQuery,
        currentPage: currentPage ?? this.currentPage,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final usersControllerProvider =
    NotifierProvider<UsersController, UsersState>(UsersController.new);

class UsersController extends Notifier<UsersState> {
  AdminUsersRepository get _repository => ref.read(adminUsersRepositoryProvider);

  @override
  UsersState build() {
    Future.microtask(loadUsers);
    return const UsersState(pageData: null, isLoading: true);
  }

  Future<void> loadUsers({String? search, int? page}) async {
    final query = search ?? state.searchQuery;
    final pageNum = page ?? state.currentPage;

    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      currentPage: pageNum,
      error: null,
    );

    try {
      final result = await _repository.listUsers(
        search: query.isEmpty ? null : query,
        page: pageNum,
        size: 15,
      );
      state = state.copyWith(
        pageData: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleActive(String userId, bool currentStatus) async {
    try {
      final updated = await _repository.setActive(userId, !currentStatus);
      _mergeModeration(userId, updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleSuspend(String userId, bool currentSuspended, {String? reason}) async {
    try {
      final updated = await _repository.setSuspended(userId, !currentSuspended, reason: reason);
      _mergeModeration(userId, updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Copies the moderation fields the server just confirmed onto the row in
  /// the current page so the list reflects it without a reload.
  void _mergeModeration(String userId, AdminUserDetail updated) {
    final page = state.pageData;
    if (page == null) return;
    state = state.copyWith(
      pageData: page.copyWith(
        content: page.content
            .map(
              (u) => u.id == userId
                  ? u.copyWith(
                      isActive: updated.isActive,
                      accountStatus: updated.accountStatus,
                      isSuspended: updated.isSuspended,
                      suspendedReason: updated.suspendedReason,
                      clearSuspendedReason: updated.suspendedReason == null,
                    )
                  : u,
            )
            .toList(),
      ),
    );
  }

  Future<AdminUserDetail?> fetchDetail(String userId) async {
    try {
      return await _repository.getUser(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createUser(AdminUserCreateRequest request) async {
    try {
      await _repository.createUser(request);
      await loadUsers(page: 0);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(String id, AdminUserUpdateRequest request) async {
    try {
      await _repository.updateUser(id, request);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
