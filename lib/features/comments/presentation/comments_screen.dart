import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../domain/admin_comment_models.dart';
import 'comments_controller.dart';
import 'room_comments_panel.dart';

/// Recent comments across the app, grouped under the room they were left on.
/// Each group opens that room's page, where its whole thread lives.
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref
        .read(commentsControllerProvider.notifier)
        .load(search: value.trim(), page: 0);
  }

  Future<void> _delete(AdminComment comment) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete Comment',
      message:
          'Remove this comment by ${comment.authorName} from '
          '"${comment.listingTitle ?? 'this room'}"? It disappears for '
          'everyone in the thread immediately.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    final ok = await ref
        .read(commentsControllerProvider.notifier)
        .delete(comment.id);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
  }

  /// Comments of one page bucketed by room, rooms in order of their newest
  /// comment.
  static List<List<AdminComment>> _groupByRoom(List<AdminComment> comments) {
    final groups = <String, List<AdminComment>>{};
    for (final comment in comments) {
      groups.putIfAbsent(comment.listingId, () => []).add(comment);
    }
    return groups.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsControllerProvider);
    final theme = Theme.of(context);
    final page = state.pageData;
    final groups = _groupByRoom(page?.content ?? const []);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment Moderation',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recent comments, grouped by room. Open a room to '
                        'see its full thread alongside its photos and details.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.read(commentsControllerProvider.notifier).load(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search comment text, author or room title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _onSearch,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (state.error != null) ...[
              AdminErrorBanner(state.error!),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: state.isLoading && page == null
                  ? const Center(child: CircularProgressIndicator())
                  : groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments found',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _RoomCommentGroup(
                        comments: groups[index],
                        onDelete: _delete,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            if (page != null && page.totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${page.page + 1} of ${page.totalPages} '
                    '(${page.totalElements} comments)',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: page.page > 0
                        ? () => ref
                              .read(commentsControllerProvider.notifier)
                              .load(page: page.page - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: !page.isLast
                        ? () => ref
                              .read(commentsControllerProvider.notifier)
                              .load(page: page.page + 1)
                        : null,
                  ),
                ],
              ),
          ],
        ),
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: openRoom,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.listingTitle?.isNotEmpty == true
                                ? room.listingTitle!
                                : 'Untitled listing',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (room.listingLocality?.isNotEmpty == true)
                                room.listingLocality!,
                              '${comments.length} recent '
                                  '${comments.length == 1 ? 'comment' : 'comments'}',
                            ].join(' • '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: openRoom,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open room'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final (index, comment) in comments.indexed) ...[
            if (index > 0) const Divider(height: 1),
            AdminCommentRow(
              comment: comment,
              onDelete: () => onDelete(comment),
            ),
          ],
        ],
      ),
    );
  }
}
