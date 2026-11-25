import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_ui.dart';
import '../data/admin_community_api.dart';
import '../domain/admin_community_models.dart';
import 'community_providers.dart';
import 'status_review_dialog.dart';
import 'widgets/community_widgets.dart';

/// Community: every post (with filters) and every status.
class AdminCommunityScreen extends StatelessWidget {
  const AdminCommunityScreen({super.key, this.initialTab = 0});

  /// 0 = Posts, 1 = Statuses.
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: AdminPage(
        title: 'Community',
        subtitle: 'Posts, comments and statuses people share in the app',
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [Tab(text: 'Posts'), Tab(text: 'Statuses')],
            ),
            SizedBox(height: 14),
            Expanded(
              child: TabBarView(children: [_PostsTab(), _StatusesTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(postsQueryProvider);
    final query = ref.read(postsQueryProvider.notifier);
    final page = ref.watch(postsPageProvider);
    final phone = context.isPhone;

    final search = AdminSearchField(
      hint: 'Search title, text or author',
      initialValue: q.search,
      onSubmitted: query.setSearch,
    );
    final category = DropdownButtonFormField<String?>(
      initialValue: q.category,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        const DropdownMenuItem(value: null, child: Text('All categories')),
        for (final e in communityCategories.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: query.setCategory,
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(postsPageProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: phone
                ? Column(children: [search, const SizedBox(height: 10), category])
                : Row(
                    children: [
                      Expanded(flex: 3, child: search),
                      const SizedBox(width: 12),
                      SizedBox(width: 240, child: category),
                    ],
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: AdminFilterBar<PostFilter>(
              filters: const [
                AdminFilter(PostFilter.all, 'All'),
                AdminFilter(PostFilter.active, 'Visible'),
                AdminFilter(PostFilter.reported, 'Flagged'),
                AdminFilter(PostFilter.pinned, 'Pinned'),
                AdminFilter(PostFilter.hidden, 'Hidden'),
              ],
              selected: q.filter,
              onSelected: query.setFilter,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          ...switch (page) {
            AsyncData(:final value) when value.content.isEmpty => [
              const SliverToBoxAdapter(
                child: AdminEmptyState(
                  icon: Icons.diversity_3_outlined,
                  title: 'No posts here',
                  message: 'Try another filter or search.',
                ),
              ),
            ],
            AsyncData(:final value) => [
              SliverList.separated(
                itemCount: value.content.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PostRow(post: value.content[i]),
              ),
              SliverToBoxAdapter(
                child: AdminPager(
                  page: value.page,
                  totalPages: value.totalPages,
                  totalElements: value.totalElements,
                  onPage: query.setPage,
                ),
              ),
            ],
            AsyncError(:final error) when !page.isLoading => [
              SliverToBoxAdapter(
                child: AdminErrorState(
                  '$error',
                  onRetry: () => ref.invalidate(postsPageProvider),
                ),
              ),
            ],
            _ => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _PostRow extends ConsumerWidget {
  const _PostRow({required this.post});

  final AdminCommunityPost post;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(AdminCommunityApi api) action,
    String done,
  ) async {
    try {
      await action(ref.read(adminCommunityApiProvider));
      refreshCommunity(ref, postId: post.id);
      if (context.mounted) showAdminSnack(context, done);
    } catch (e) {
      if (context.mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final p = post;
    final phone = context.isPhone;
    final chips = postStateChips(p);
    return AdminCard(
      padding: const EdgeInsets.all(12),
      borderColor: p.isFlagged ? const Color(0xFFF6C177) : null,
      onTap: () => context.go(Routes.communityPost(p.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostThumb(post: p, size: phone ? 56 : 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title.isEmpty ? p.content : p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.authorName} · ${p.categoryLabel} · ${timeAgo(p.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...chips,
                    _Count(Icons.favorite_border_rounded, p.likesCount, 'likes'),
                    _Count(Icons.mode_comment_outlined, p.commentsCount, 'comments'),
                    if (p.imageUrls.length > 1)
                      _Count(Icons.photo_library_outlined, p.imageUrls.length, 'photos'),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Post actions',
            onSelected: (v) => switch (v) {
              'pin' => _act(
                context,
                ref,
                (api) => api.setPinned(p.id, !p.isPinned),
                p.isPinned ? 'Unpinned' : 'Pinned to the top of the feed',
              ),
              'hide' => _act(
                context,
                ref,
                (api) => api.setStatus(p.id, 'ARCHIVED'),
                'Post hidden from the app',
              ),
              'restore' => _act(
                context,
                ref,
                (api) => api.setStatus(p.id, 'ACTIVE'),
                'Post is visible again',
              ),
              _ => context.go(Routes.communityPost(p.id)),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'open', child: Text('Open post')),
              PopupMenuItem(
                value: 'pin',
                child: Text(p.isPinned ? 'Unpin' : 'Pin to top'),
              ),
              p.isActive
                  ? const PopupMenuItem(value: 'hide', child: Text('Hide from app'))
                  : const PopupMenuItem(value: 'restore', child: Text('Restore')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.icon, this.count, this.what);

  final IconData icon;
  final int count;
  final String what;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count $what',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text('$count', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusesTab extends ConsumerWidget {
  const _StatusesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(statusesQueryProvider);
    final query = ref.read(statusesQueryProvider.notifier);
    final page = ref.watch(statusesPageProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(statusesPageProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AdminSearchField(
              hint: 'Search by name or caption',
              initialValue: q.search,
              onSubmitted: query.setSearch,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: AdminFilterBar<StatusFilter>(
              filters: const [
                AdminFilter(StatusFilter.live, 'Live'),
                AdminFilter(StatusFilter.reported, 'Reported'),
                AdminFilter(StatusFilter.expired, 'Expired'),
                AdminFilter(StatusFilter.all, 'All'),
              ],
              selected: q.filter,
              onSelected: query.setFilter,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          ...switch (page) {
            AsyncData(:final value) when value.content.isEmpty => [
              SliverToBoxAdapter(
                child: AdminEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: q.filter == StatusFilter.live
                      ? 'No live statuses'
                      : 'No statuses here',
                  message: 'Statuses disappear from the app after 24 hours.',
                ),
              ),
            ],
            AsyncData(:final value) => [
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: context.isPhone ? 200 : 220,
                  childAspectRatio: 9 / 16,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: value.content.length,
                itemBuilder: (_, i) {
                  final s = value.content[i];
                  return StatusTile(
                    status: s,
                    onTap: () => showStatusReviewDialog(context, statusId: s.id),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: AdminPager(
                  page: value.page,
                  totalPages: value.totalPages,
                  totalElements: value.totalElements,
                  onPage: query.setPage,
                ),
              ),
            ],
            AsyncError(:final error) when !page.isLoading => [
              SliverToBoxAdapter(
                child: AdminErrorState(
                  '$error',
                  onRetry: () => ref.invalidate(statusesPageProvider),
                ),
              ),
            ],
            _ => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
