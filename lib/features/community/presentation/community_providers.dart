import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/dashboard_providers.dart';
import '../data/admin_community_api.dart';
import '../domain/admin_community_models.dart';

/// Everything on one post's page.
final postDetailProvider = FutureProvider.autoDispose
    .family<AdminPostDetail, String>(
      (ref, id) => ref.watch(adminCommunityApiProvider).getPost(id),
    );

/// One status and its reports.
final statusDetailProvider = FutureProvider.autoDispose
    .family<AdminStatusDetail, String>(
      (ref, id) => ref.watch(adminCommunityApiProvider).getStatus(id),
    );

/// A user's posts and statuses, for their profile page.
final userPostsProvider = FutureProvider.autoDispose
    .family<Paged<AdminCommunityPost>, String>(
      (ref, userId) => ref
          .watch(adminCommunityApiProvider)
          .listPosts(authorId: userId, size: 10),
    );

final userStatusesProvider = FutureProvider.autoDispose
    .family<Paged<AdminUserStatus>, String>(
      (ref, userId) => ref
          .watch(adminCommunityApiProvider)
          .listStatuses(userId: userId, filter: StatusFilter.all, size: 12),
    );

/// State of a paged, filterable list.
class ListQuery<F> {
  const ListQuery({
    required this.filter,
    this.search = '',
    this.category,
    this.page = 0,
  });

  final F filter;
  final String search;
  final String? category;
  final int page;

  ListQuery<F> copyWith({
    F? filter,
    String? search,
    String? category,
    bool clearCategory = false,
    int? page,
  }) => ListQuery(
    filter: filter ?? this.filter,
    search: search ?? this.search,
    category: clearCategory ? null : (category ?? this.category),
    page: page ?? this.page,
  );
}

class PostsQueryNotifier extends Notifier<ListQuery<PostFilter>> {
  @override
  ListQuery<PostFilter> build() => const ListQuery(filter: PostFilter.all);

  void setFilter(PostFilter f) => state = state.copyWith(filter: f, page: 0);
  void setSearch(String s) => state = state.copyWith(search: s, page: 0);
  void setCategory(String? c) =>
      state = state.copyWith(category: c, clearCategory: c == null, page: 0);
  void setPage(int p) => state = state.copyWith(page: p);
}

final postsQueryProvider =
    NotifierProvider<PostsQueryNotifier, ListQuery<PostFilter>>(
      PostsQueryNotifier.new,
    );

final postsPageProvider = FutureProvider.autoDispose<Paged<AdminCommunityPost>>((
  ref,
) {
  final q = ref.watch(postsQueryProvider);
  return ref
      .watch(adminCommunityApiProvider)
      .listPosts(
        filter: q.filter,
        search: q.search,
        category: q.category,
        page: q.page,
      );
});

class StatusesQueryNotifier extends Notifier<ListQuery<StatusFilter>> {
  @override
  ListQuery<StatusFilter> build() => const ListQuery(filter: StatusFilter.live);

  void setFilter(StatusFilter f) => state = state.copyWith(filter: f, page: 0);
  void setSearch(String s) => state = state.copyWith(search: s, page: 0);
  void setPage(int p) => state = state.copyWith(page: p);
}

final statusesQueryProvider =
    NotifierProvider<StatusesQueryNotifier, ListQuery<StatusFilter>>(
      StatusesQueryNotifier.new,
    );

final statusesPageProvider = FutureProvider.autoDispose<Paged<AdminUserStatus>>((
  ref,
) {
  final q = ref.watch(statusesQueryProvider);
  return ref
      .watch(adminCommunityApiProvider)
      .listStatuses(filter: q.filter, search: q.search, page: q.page);
});

class CommunityCommentsQueryNotifier extends Notifier<ListQuery<bool>> {
  /// filter = reported only.
  @override
  ListQuery<bool> build() => const ListQuery(filter: false);

  void setReportedOnly(bool v) => state = state.copyWith(filter: v, page: 0);
  void setSearch(String s) => state = state.copyWith(search: s, page: 0);
  void setPage(int p) => state = state.copyWith(page: p);
}

final communityCommentsQueryProvider =
    NotifierProvider<CommunityCommentsQueryNotifier, ListQuery<bool>>(
      CommunityCommentsQueryNotifier.new,
    );

final communityCommentsPageProvider =
    FutureProvider.autoDispose<Paged<AdminCommunityComment>>((ref) {
      final q = ref.watch(communityCommentsQueryProvider);
      return ref
          .watch(adminCommunityApiProvider)
          .listComments(reportedOnly: q.filter, search: q.search, page: q.page);
    });

/// Refreshes every community list and the Overview numbers after a change.
void refreshCommunity(WidgetRef ref, {String? postId, String? statusId}) {
  ref.invalidate(postsPageProvider);
  ref.invalidate(statusesPageProvider);
  ref.invalidate(communityCommentsPageProvider);
  ref.invalidate(dashboardStatsProvider);
  if (postId != null) ref.invalidate(postDetailProvider(postId));
  if (statusId != null) ref.invalidate(statusDetailProvider(statusId));
}
