import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_comments_repository.dart';
import '../domain/admin_comment_models.dart';

class CommentsState {
  const CommentsState({
    this.pageData,
    this.searchQuery = '',
    this.listingIdFilter,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  final AdminCommentPage? pageData;
  final String searchQuery;

  /// Narrow the log to one room (set from a listing id typed in the filter).
  final String? listingIdFilter;
  final int currentPage;
  final bool isLoading;
  final String? error;

  CommentsState copyWith({
    AdminCommentPage? pageData,
    String? searchQuery,
    String? listingIdFilter,
    bool clearListingIdFilter = false,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) =>
      CommentsState(
        pageData: pageData ?? this.pageData,
        searchQuery: searchQuery ?? this.searchQuery,
        listingIdFilter:
            clearListingIdFilter ? null : (listingIdFilter ?? this.listingIdFilter),
        currentPage: currentPage ?? this.currentPage,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final commentsControllerProvider =
    NotifierProvider<CommentsController, CommentsState>(CommentsController.new);

class CommentsController extends Notifier<CommentsState> {
  AdminCommentsRepository get _repo => ref.read(adminCommentsRepositoryProvider);

  @override
  CommentsState build() {
    Future.microtask(load);
    return const CommentsState(isLoading: true);
  }

  Future<void> load({String? search, int? page}) async {
    final query = search ?? state.searchQuery;
    final pageNum = page ?? state.currentPage;
    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      currentPage: pageNum,
      error: null,
    );
    try {
      final result = await _repo.list(
        search: query.isEmpty ? null : query,
        listingId: state.listingIdFilter,
        page: pageNum,
        size: 20,
      );
      state = state.copyWith(pageData: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setListingFilter(String? listingId) async {
    state = state.copyWith(
      listingIdFilter: listingId,
      clearListingIdFilter: listingId == null,
    );
    await load(page: 0);
  }

  Future<AdminComment?> fetchDetail(String id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Removes the comment server-side (broadcasts COMMENT_DELETED to the room)
  /// and drops it from the current page without a refetch.
  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      final page = state.pageData;
      if (page != null) {
        state = state.copyWith(
          pageData: AdminCommentPage(
            content: page.content.where((c) => c.id != id).toList(),
            page: page.page,
            totalElements: page.totalElements > 0 ? page.totalElements - 1 : 0,
            totalPages: page.totalPages,
            isLast: page.isLast,
          ),
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
