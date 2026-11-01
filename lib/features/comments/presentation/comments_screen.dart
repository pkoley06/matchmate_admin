import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_comment_models.dart';
import 'comments_controller.dart';

/// Comment moderation log: every room comment, newest first, searchable by
/// text / author / room and narrowable to one listing. Inspect or delete.
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _searchController = TextEditingController();
  final _listingIdController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _listingIdController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    ref.read(commentsControllerProvider.notifier).load(search: value.trim(), page: 0);
  }

  void _onListingFilter(String value) {
    final trimmed = value.trim();
    ref
        .read(commentsControllerProvider.notifier)
        .setListingFilter(trimmed.isEmpty ? null : trimmed);
  }

  Future<void> _showDetail(AdminComment comment) async {
    final detail = await ref.read(commentsControllerProvider.notifier).fetchDetail(comment.id);
    if (!mounted || detail == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _CommentDetailDialog(
        comment: detail,
        onDelete: () => _confirmDelete(detail),
      ),
    );
  }

  void _confirmDelete(AdminComment comment) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: Text(
          'Remove this comment by ${comment.authorName} from "${comment.listingTitle ?? 'Listing #${comment.listingId}'}"? '
          'It disappears for everyone in the thread immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(commentsControllerProvider.notifier)
                  .delete(comment.id);
              if (!mounted || !ok) return;
              // Close the detail dialog if it is still open.
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsControllerProvider);
    final theme = Theme.of(context);
    final page = state.pageData;

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
                        'Every comment left on a room listing, newest first. Inspect context or remove abuse.',
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
                  onPressed: () => ref.read(commentsControllerProvider.notifier).load(),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
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
                        onSubmitted: _onSearch,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _listingIdController,
                        decoration: InputDecoration(
                          hintText: 'Listing ID',
                          prefixIcon: const Icon(Icons.home_outlined, size: 20),
                          suffixIcon: state.listingIdFilter != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _listingIdController.clear();
                                    _onListingFilter('');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: _onListingFilter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: state.isLoading && page == null
                  ? const Center(child: CircularProgressIndicator())
                  : (page == null || page.content.isEmpty)
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
                              Text('No comments found', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            itemCount: page.content.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final c = page.content[index];
                              return _CommentTile(
                                comment: c,
                                onInspect: () => _showDetail(c),
                                onDelete: () => _confirmDelete(c),
                                onFilterListing: () {
                                  _listingIdController.text = c.listingId;
                                  _onListingFilter(c.listingId);
                                },
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 12),

            if (page != null && page.totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${page.page + 1} of ${page.totalPages} (${page.totalElements} total)',
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onInspect,
    required this.onDelete,
    required this.onFilterListing,
  });

  final AdminComment comment;
  final VoidCallback onInspect;
  final VoidCallback onDelete;
  final VoidCallback onFilterListing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = comment.authorAvatarUrl?.startsWith('http') == true;

    return ListTile(
      onTap: onInspect,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        backgroundImage: hasAvatar ? NetworkImage(comment.authorAvatarUrl!) : null,
        child: hasAvatar
            ? null
            : Text(
                comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
      title: Row(
        children: [
          Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (comment.authorIsHost) ...[
            const SizedBox(width: 6),
            _Tag(label: 'Host', color: Colors.amber.shade800),
          ],
          if (comment.authorSuspended) ...[
            const SizedBox(width: 6),
            _Tag(label: 'Suspended', color: Colors.red.shade700),
          ],
          const SizedBox(width: 10),
          Text(
            _formatDate(comment.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const Spacer(),
          Icon(Icons.favorite_border, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 3),
          Text('${comment.likesCount}', style: theme.textTheme.bodySmall),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(comment.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          InkWell(
            onTap: onFilterListing,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_outlined, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${comment.listingTitle ?? 'Listing'} #${comment.listingId}'
                  '${comment.listingLocality != null ? ' · ${comment.listingLocality}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Inspect',
            onPressed: onInspect,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete comment',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CommentDetailDialog extends StatelessWidget {
  const _CommentDetailDialog({required this.comment, required this.onDelete});

  final AdminComment comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.forum_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comment #${comment.id}'),
                Text(
                  'By ${comment.authorName} (user #${comment.authorUserId})',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(comment.content, style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(height: 16),
            _infoTile('Room', '${comment.listingTitle ?? 'Listing'} (#${comment.listingId})'),
            _infoTile('Locality', comment.listingLocality ?? 'N/A'),
            _infoTile('Room host', 'User #${comment.listingHostUserId ?? '?'}${comment.authorIsHost ? ' (this author)' : ''}'),
            _infoTile('Author status', comment.authorSuspended ? 'Suspended' : 'In good standing'),
            _infoTile('Likes', '${comment.likesCount}'),
            _infoTile('Posted', _formatDate(comment.createdAt)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete comment'),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
