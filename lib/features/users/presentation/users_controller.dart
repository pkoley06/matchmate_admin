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

  Future<void> toggleActive(int userId, bool currentStatus) async {
    try {
      final updated = await _repository.setActive(userId, !currentStatus);
      if (state.pageData != null) {
        final updatedContent = state.pageData!.content.map((u) {
          if (u.id == userId) {
            return AdminUserSummary(
              id: u.id,
              fullName: u.fullName,
              gender: u.gender,
              age: u.age,
              lastKnownLocality: u.lastKnownLocality,
              primaryAuthProvider: u.primaryAuthProvider,
              isActive: updated.isActive,
              isSuspended: updated.isSuspended,
              suspendedReason: updated.suspendedReason,
              onboardingCompleted: u.onboardingCompleted,
              createdAt: u.createdAt,
            );
          }
          return u;
        }).toList();

        state = state.copyWith(
          pageData: AdminUserPage(
            content: updatedContent,
            page: state.pageData!.page,
            size: state.pageData!.size,
            totalElements: state.pageData!.totalElements,
            totalPages: state.pageData!.totalPages,
            isLast: state.pageData!.isLast,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleSuspend(int userId, bool currentSuspended, {String? reason}) async {
    try {
      final updated = await _repository.setSuspended(userId, !currentSuspended, reason: reason);
      if (state.pageData != null) {
        final updatedContent = state.pageData!.content.map((u) {
          if (u.id == userId) {
            return AdminUserSummary(
              id: u.id,
              fullName: u.fullName,
              gender: u.gender,
              age: u.age,
              lastKnownLocality: u.lastKnownLocality,
              primaryAuthProvider: u.primaryAuthProvider,
              isActive: updated.isActive,
              isSuspended: updated.isSuspended,
              suspendedReason: updated.suspendedReason,
              onboardingCompleted: u.onboardingCompleted,
              createdAt: u.createdAt,
            );
          }
          return u;
        }).toList();

        state = state.copyWith(
          pageData: AdminUserPage(
            content: updatedContent,
            page: state.pageData!.page,
            size: state.pageData!.size,
            totalElements: state.pageData!.totalElements,
            totalPages: state.pageData!.totalPages,
            isLast: state.pageData!.isLast,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<AdminUserDetail?> fetchDetail(int userId) async {
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

  Future<bool> updateUser(int id, AdminUserUpdateRequest request) async {
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
