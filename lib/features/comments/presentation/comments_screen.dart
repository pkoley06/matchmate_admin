import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../community/data/admin_community_api.dart';
import '../../community/domain/admin_community_models.dart';
import '../../community/presentation/community_providers.dart';
import '../domain/admin_comment_models.dart';
import 'comments_controller.dart';
import 'room_comments_panel.dart';

/// Recent comments across the app: on rooms, and on community posts.
class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: AdminPage(
        title: 'Comments',
        subtitle: 'Newest first. Open a room or post to see the whole thread.',
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [Tab(text: 'Rooms'), Tab(text: 'Community')],
            ),
            SizedBox(height: 14),
            Expanded(
              child: TabBarView(
                children: [_RoomCommentsTab(), _CommunityCommentsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rooms ──────────────────────────────────────────────────────────────────

class _RoomCommentsTab extends ConsumerWidget {
  const _RoomCommentsTab();

  /// Comments of one page bucketed by room, rooms in order of their newest
  /// comment.
  static List<List<AdminComment>> _groupByRoom(List<AdminComment> comments) {
    final groups = <String, List<AdminComment>>{};
    for (final comment in comments) {
      groups.putIfAbsent(comment.listingId, () => []).add(comment);
    }
    return groups.values.toList();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AdminComment comment,
  ) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete comment?',
      message:
          'Remove this comment by ${comment.authorName} from '
          '"${comment.listingTitle ?? 'this room'}"? It disappears for '
          'everyone in the thread immediately.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    final ok = await ref.read(commentsControllerProvider.notifier).delete(comment.id);
    if (ok && context.mounted) showAdminSnack(context, 'Comment deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentsControllerProvider);
    final controller = ref.read(commentsControllerProvider.notifier);
    final page = state.pageData;
    final groups = _groupByRoom(page?.content ?? const []);

    return RefreshIndicator(
      onRefresh: () => controller.load(),
      child: ListView(
        children: [
          AdminSearchField(
            hint: 'Search comment text, author or room title',
            initialValue: state.searchQuery,
            onSubmitted: (v) => controller.load(search: v, page: 0),
          ),
          const SizedBox(height: 14),
          if (state.error != null) ...[
            AdminErrorBanner(state.error!, onRetry: () => controller.load()),
            const SizedBox(height: 14),
          ],
          if (state.isLoading && page == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (groups.isEmpty)
            const AdminEmptyState(
              icon: Icons.forum_outlined,
              title: 'No comments found',
            )
          else
            for (final g in groups) ...[
              _RoomCommentGroup(
                comments: g,
                onDelete: (c) => _delete(context, ref, c),
              ),
              const SizedBox(height: 12),
            ],
          if (page != null)
            AdminPager(
              page: page.page,
              totalPages: page.totalPages,
              totalElements: page.totalElements,
              onPage: (p) => controller.load(page: p),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// One room's recent comments under a header that opens the room.
class _RoomCommentGroup extends StatelessWidget {
  const _RoomCommentGroup({required this.comments, required this.onDelete});

  /// Never empty; all on the same room.
  final List<AdminComment> comments;
  final ValueChanged<AdminComment> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = comments.first;
    void openRoom() => context.go(Routes.room(room.listingId));

    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainer,
            child: InkWell(
              onTap: openRoom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.bed_outlined, color: BrandColors.coralInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.listingTitle?.isNotEmpty == true
                                ? room.listingTitle!
                                : 'Untitled listing',
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (room.listingLocality?.isNotEmpty == true)
                                room.listingLocality!,
                              '${comments.length} recent '
                                  '${comments.length == 1 ? 'comment' : 'comments'}',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          for (final (index, comment) in comments.indexed) ...[
            if (index > 0) const Divider(height: 1),
            AdminCommentRow(comment: comment, onDelete: () => onDelete(comment)),
          ],
        ],
      ),
    );
  }
}

// ── Community ──────────────────────────────────────────────────────────────

class _CommunityCommentsTab extends ConsumerWidget {
  const _CommunityCommentsTab();

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(AdminCommunityApi api) action,
    String done,
  ) async {
    try {
      await action(ref.read(adminCommunityApiProvider));
      refreshCommunity(ref);
      if (context.mounted) showAdminSnack(context, done);
    } catch (e) {
      if (context.mounted) showAdminSnack(context, '$e', error: true);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AdminCommunityComment c,
  ) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete comment?',
      message:
          'Remove this comment by ${c.authorName}? Replies under it are '
          'removed too, and its open reports are marked as handled.',
      confirmLabel: 'Delete',
    );
    if (ok && context.mounted) {
      await _run(context, ref, (api) => api.deleteComment(c.id), 'Comment deleted');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(communityCommentsQueryProvider);
    final query = ref.read(communityCommentsQueryProvider.notifier);
    final page = ref.watch(communityCommentsPageProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(communityCommentsPageProvider.future),
      child: ListView(
        children: [
          AdminSearchField(
            hint: 'Search comment text, author or post',
            initialValue: q.search,
            onSubmitted: query.setSearch,
          ),
          const SizedBox(height: 12),
          AdminFilterBar<bool>(
            filters: const [
              AdminFilter(false, 'All'),
              AdminFilter(true, 'Reported'),
            ],
            selected: q.filter,
            onSelected: query.setReportedOnly,
          ),
          const SizedBox(height: 14),
          ...switch (page) {
            AsyncData(:final value) when value.content.isEmpty => [
              AdminEmptyState(
                icon: Icons.forum_outlined,
                title: q.filter ? 'No reported comments' : 'No comments found',
              ),
            ],
            AsyncData(:final value) => [
              for (final c in value.content) ...[
                _CommunityCommentCard(
                  comment: c,
                  onDelete: () => _delete(context, ref, c),
                  onDismiss: () => _run(
                    context,
                    ref,
                    (api) => api.dismissCommentReports(c.id),
                    'Reports dismissed',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AdminPager(
                page: value.page,
                totalPages: value.totalPages,
                totalElements: value.totalElements,
                onPage: query.setPage,
              ),
            ],
            AsyncError(:final error) when !page.isLoading => [
              AdminErrorState(
                '$error',
                onRetry: () => ref.invalidate(communityCommentsPageProvider),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CommunityCommentCard extends StatelessWidget {
  const _CommunityCommentCard({
    required this.comment,
    required this.onDelete,
    required this.onDismiss,
  });

  final AdminCommunityComment comment;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = comment;
    return AdminCard(
      padding: const EdgeInsets.all(14),
      borderColor: c.pendingReports > 0 ? BrandColors.coral : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go(Routes.user(c.authorId)),
            child: AdminAvatar(url: c.authorAvatarUrl, name: c.authorName, radius: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(c.authorName, style: theme.textTheme.titleSmall),
                    if (c.byPostAuthor) const AdminChip('Post author', tone: ChipTone.info),
                    if (c.depth > 0) const AdminChip('Reply'),
                    if (c.pendingReports > 0)
                      AdminChip('Reported · ${c.pendingReports}', tone: ChipTone.danger),
                    Text(timeAgo(c.createdAt), style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(c.content, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => context.go(Routes.communityPost(c.postId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'On “${(c.postTitle ?? '').isEmpty ? 'a post' : c.postTitle}”'
                            '${c.postStatus != null && c.postStatus != 'ACTIVE' ? ' (hidden)' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                    if (c.pendingReports > 0)
                      TextButton(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: onDismiss,
                        child: const Text('Dismiss reports'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
