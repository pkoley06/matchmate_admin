import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../data/admin_comments_repository.dart';
import '../domain/admin_comment_models.dart';

/// One comment: who wrote it, when, the text, and a delete control. The
/// author's photo and name open that user's page.
class AdminCommentRow extends StatelessWidget {
  const AdminCommentRow({
    super.key,
    required this.comment,
    required this.onDelete,
  });

  final AdminComment comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void openAuthor() => context.go(Routes.user(comment.authorUserId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: openAuthor,
            customBorder: const CircleBorder(),
            child: AdminAvatar(
              url: comment.authorAvatarUrl,
              name: comment.authorName,
              radius: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: openAuthor,
                      child: Text(
                        comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (comment.authorIsHost)
                      AdminTag(label: 'Host', color: Colors.amber.shade800),
                    if (comment.authorSuspended)
                      AdminTag(label: 'Suspended', color: Colors.red.shade700),
                    Text(
                      formatAdminDate(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${comment.likesCount}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(comment.content),
              ],
            ),
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

/// Confirms, then deletes [comment]. True when it is gone.
Future<bool> confirmAndDeleteComment(
  BuildContext context,
  WidgetRef ref,
  AdminComment comment,
) async {
  final confirmed = await confirmAdminAction(
    context,
    title: 'Delete Comment',
    message:
        'Remove this comment by ${comment.authorName}? It disappears for '
        'everyone in the thread immediately.',
    confirmLabel: 'Delete',
  );
  if (!confirmed) return false;
  try {
    await ref.read(adminCommentsRepositoryProvider).delete(comment.id);
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
    return false;
  }
}

/// Every comment left on one room, newest first — shown inside the room's
/// detail screen.
class RoomCommentsPanel extends ConsumerStatefulWidget {
  const RoomCommentsPanel({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<RoomCommentsPanel> createState() => _RoomCommentsPanelState();
}

class _RoomCommentsPanelState extends ConsumerState<RoomCommentsPanel> {
  static const _pageSize = 20;

  List<AdminComment> _comments = [];
  int _total = 0;
  int _nextPage = 0;
  bool _isLast = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(adminCommentsRepositoryProvider)
          .list(
            listingId: widget.listingId,
            page: reset ? 0 : _nextPage,
            size: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _comments = reset ? page.content : [..._comments, ...page.content];
        _total = page.totalElements;
        _nextPage = page.page + 1;
        _isLast = page.isLast;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _delete(AdminComment comment) async {
    final deleted = await confirmAndDeleteComment(context, ref, comment);
    if (!deleted || !mounted) return;
    setState(() {
      _comments = _comments.where((c) => c.id != comment.id).toList();
      if (_total > 0) _total--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminSectionCard(
      title: 'Comments ($_total)',
      padding: const EdgeInsets.only(top: 16),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          tooltip: 'Refresh comments',
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : () => _load(reset: true),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AdminErrorBanner(
                _error!,
                onRetry: () => _load(reset: true),
              ),
            ),
          if (_comments.isEmpty && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Text(
                'Nobody has commented on this room yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final (index, comment) in _comments.indexed) ...[
            if (index > 0) const Divider(height: 1),
            AdminCommentRow(
              comment: comment,
              onDelete: () => _delete(comment),
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (!_isLast)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: _load,
                child: const Text('Load more comments'),
              ),
            ),
        ],
      ),
    );
  }
}
