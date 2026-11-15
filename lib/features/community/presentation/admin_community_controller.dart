import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_community_api.dart';
import '../domain/admin_community_models.dart';

class CommunityState {
  const CommunityState({
    this.postsPage,
    this.statusesPage,
    this.searchQuery = '',
    this.categoryFilter,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  final AdminCommunityPostPage? postsPage;
  final AdminUserStatusPage? statusesPage;
  final String searchQuery;
  final String? categoryFilter;
  final int currentPage;
  final bool isLoading;
  final String? error;

  CommunityState copyWith({
    AdminCommunityPostPage? postsPage,
    AdminUserStatusPage? statusesPage,
    String? searchQuery,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) =>
      CommunityState(
        postsPage: postsPage ?? this.postsPage,
        statusesPage: statusesPage ?? this.statusesPage,
        searchQuery: searchQuery ?? this.searchQuery,
        categoryFilter: clearCategoryFilter
            ? null
            : (categoryFilter ?? this.categoryFilter),
        currentPage: currentPage ?? this.currentPage,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final communityControllerProvider =
    NotifierProvider<CommunityController, CommunityState>(CommunityController.new);

class CommunityController extends Notifier<CommunityState> {
  AdminCommunityApi get _api => ref.read(adminCommunityApiProvider);

  @override
  CommunityState build() {
    Future.microtask(loadAll);
    return const CommunityState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _api.listPosts(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        category: state.categoryFilter,
        page: state.currentPage,
      );
      final statuses = await _api.listStatuses();
      state = state.copyWith(
        postsPage: posts,
        statusesPage: statuses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setSearch(String query) async {
    state = state.copyWith(searchQuery: query, currentPage: 0);
    await loadAll();
  }

  Future<void> setCategory(String? category) async {
    state = state.copyWith(
      categoryFilter: category,
      clearCategoryFilter: category == null,
      currentPage: 0,
    );
    await loadAll();
  }

  Future<void> deletePost(String id) async {
    await _api.deletePost(id);
    await loadAll();
  }

  Future<void> deleteStatus(String id) async {
    await _api.deleteStatus(id);
    await loadAll();
  }
}
