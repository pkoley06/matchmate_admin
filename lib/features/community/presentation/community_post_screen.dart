import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../reports/presentation/report_target.dart';
import '../data/admin_community_api.dart';
import '../domain/admin_community_models.dart';
import 'community_providers.dart';
import 'widgets/community_widgets.dart';

/// One community post: photos, text, comments, reports and moderation.
class CommunityPostScreen extends ConsumerWidget {
  const CommunityPostScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(postDetailProvider(postId));
    void back() => context.go(Routes.community);

    return switch (detail) {
      AsyncData(:final value) => _PostPage(detail: value, onBack: back),
      AsyncError(:final error) when !detail.isLoading => AdminPage(
        title: 'Post',
        breadcrumb: 'Community · Posts',
        onBack: back,
        child: AdminErrorState(
          '$error',
          onRetry: () => ref.invalidate(postDetailProvider(postId)),
        ),
      ),
      _ => AdminPage(
        title: 'Post',
        breadcrumb: 'Community · Posts',
        onBack: back,
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

class _PostPage extends ConsumerStatefulWidget {
  const _PostPage({required this.detail, required this.onBack});

  final AdminPostDetail detail;
  final VoidCallback onBack;

  @override
  ConsumerState<_PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<_PostPage> {
  bool _busy = false;

  AdminCommunityPost get _post => widget.detail.post;

  Future<void> _run(
    Future<void> Function(AdminCommunityApi api) action,
    String done,
  ) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(adminCommunityApiProvider));
      if (!mounted) return;
      refreshCommunity(ref, postId: _post.id);
      showAdminSnack(context, done);
    } catch (e) {
      if (mounted) showAdminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hide() async {
    final ok = await confirmAdminAction(
      context,
      title: 'Hide this post?',
      message:
          'It disappears from the app for everyone, including its comments. '
          'Its open reports are marked as handled. You can restore it later.',
      confirmLabel: 'Hide post',
    );
    if (ok) {
      await _run((api) => api.setStatus(_post.id, 'ARCHIVED'), 'Post hidden');
    }
  }

  Future<void> _removePhoto(String url, int index) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Remove photo ${index + 1}?',
      message: 'The rest of the post stays as it is. This can’t be undone.',
      confirmLabel: 'Remove photo',
    );
    if (ok) await _run((api) => api.removePhoto(_post.id, url), 'Photo removed');
  }

  Future<void> _deleteComment(AdminCommunityComment c, int replies) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Delete this comment?',
      message: replies == 0
          ? '“${_short(c.content)}” by ${c.authorName} will be removed.'
          : '“${_short(c.content)}” by ${c.authorName} and the $replies '
                '${replies == 1 ? 'reply' : 'replies'} under it will be removed.',
      confirmLabel: 'Delete',
    );
    if (ok) await _run((api) => api.deleteComment(c.id), 'Comment deleted');
  }

  static String _short(String s) =>
      s.length > 80 ? '${s.substring(0, 80)}…' : s;

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final p = d.post;
    final wide = context.screenWidth >= 1100;

    final gallery = p.imageUrls.isEmpty
        ? null
        : _Gallery(
            urls: p.imageUrls,
            busy: _busy,
            onRemove: _removePhoto,
          );
    final content = _ContentCard(post: p);
    final moderation = _ModerationCard(
      post: p,
      busy: _busy,
      onPin: () => _run(
        (api) => api.setPinned(p.id, !p.isPinned),
        p.isPinned ? 'Unpinned' : 'Pinned to the top of the feed',
      ),
      onHide: _hide,
      onRestore: () =>
          _run((api) => api.setStatus(p.id, 'ACTIVE'), 'Post is visible again'),
      onDismiss: () =>
          _run((api) => api.dismissPostReports(p.id), 'Reports dismissed'),
    );
    final reports = AdminCard(
      title: 'Reports (${d.reports.length})',
      subtitle: 'About this post and its comments',
      child: ReportList(reports: d.reports, showKind: true),
    );
    final author = _AuthorCard(post: p, stats: d.author);
    final room = p.taggedListingId == null ? null : _TaggedRoomCard(post: p);
    final comments = _CommentsCard(
      comments: d.comments,
      busy: _busy,
      onDelete: _deleteComment,
      onDismiss: (c) =>
          _run((api) => api.dismissCommentReports(c.id), 'Reports dismissed'),
    );

    const gap = SizedBox(height: 16);
    final Widget body = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [?gallery, if (gallery != null) gap, content, gap, comments],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [moderation, gap, reports, gap, author, if (room != null) ...[gap, room]],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              moderation,
              gap,
              ?gallery,
              if (gallery != null) gap,
              content,
              gap,
              if (d.reports.isNotEmpty) ...[reports, gap],
              comments,
              gap,
              author,
              if (room != null) ...[gap, room],
            ],
          );

    return AdminPage(
      breadcrumb: 'Community · Posts',
      onBack: widget.onBack,
      title: p.title.isEmpty ? 'Post by ${p.authorName}' : p.title,
      actions: [
        AdminChip(p.categoryLabel, tone: ChipTone.info),
        ...postStateChips(p),
      ],
      onRefresh: () => ref.refresh(postDetailProvider(p.id).future),
      child: body,
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls, required this.busy, required this.onRemove});

  final List<String> urls;
  final bool busy;
  final void Function(String url, int index) onRemove;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final i = _index.clamp(0, urls.length - 1);
    return AdminCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => showImageViewer(context, urls, initialIndex: i),
                    child: Semantics(
                      image: true,
                      label: 'Post photo ${i + 1} of ${urls.length}',
                      child: AdminNetworkImage(url: urls[i], fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: AdminChip('${i + 1} / ${urls.length}'),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: BrandColors.dangerInk,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: widget.busy
                          ? null
                          : () => widget.onRemove(urls[i], i),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove photo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (urls.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, j) => Semantics(
                  button: true,
                  selected: j == i,
                  label: 'Show photo ${j + 1}',
                  child: GestureDetector(
                    onTap: () => setState(() => _index = j),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: j == i ? BrandColors.coral : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AdminNetworkImage(
                          url: urls[j],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.post});

  final AdminCommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = post;
    final meta = [
      ?p.place,
      'posted ${timeAgo(p.createdAt)}',
    ].join(' · ');
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.priceAmount != null)
            Text(
              '₹${p.priceAmount}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(meta, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SelectableText(
            p.content.trim().isEmpty ? '(No text)' : p.content.trim(),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text('${p.likesCount} likes', style: theme.textTheme.bodyMedium),
              Text('${p.commentsCount} comments', style: theme.textTheme.bodyMedium),
              Text(p.isPinned ? 'Pinned' : 'Not pinned', style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({
    required this.post,
    required this.busy,
    required this.onPin,
    required this.onHide,
    required this.onRestore,
    required this.onDismiss,
  });

  final AdminCommunityPost post;
  final bool busy;
  final VoidCallback onPin;
  final VoidCallback onHide;
  final VoidCallback onRestore;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = post;
    final danger = theme.colorScheme.error;
    return AdminCard(
      title: 'Moderation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                p.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18,
                color: p.isActive ? BrandColors.okInk : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.isActive ? 'Visible in the app' : 'Hidden from the app',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            p.isActive
                ? 'Hidden posts disappear from the app for everyone. You can restore them later.'
                : 'Only you can see it here. Restore it to put it back in the feed.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (p.isFlagged) ...[
            FilledButton.icon(
              onPressed: busy ? null : onDismiss,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Keep post, dismiss ${p.pendingReports} '
                'report${p.pendingReports == 1 ? '' : 's'}',
              ),
            ),
            const SizedBox(height: 8),
          ],
          p.isActive
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: BorderSide(color: danger.withValues(alpha: 0.4)),
                  ),
                  onPressed: busy ? null : onHide,
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Hide post'),
                )
              : FilledButton.icon(
                  onPressed: busy ? null : onRestore,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Restore post'),
                ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy || !p.isActive ? null : onPin,
            icon: Icon(
              p.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              size: 18,
            ),
            label: Text(p.isPinned ? 'Unpin' : 'Pin to top of feed'),
          ),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.post, required this.stats});

  final AdminCommunityPost post;
  final AdminAuthorStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      title: 'Author',
      onTap: () => context.go(Routes.user(post.authorId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAvatar(url: post.authorAvatarUrl, name: post.authorName, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: theme.textTheme.titleSmall),
                    Text(
                      [
                        ?post.authorOccupation,
                        if (stats.joinedAt != null) 'joined ${timeAgo(stats.joinedAt)}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (stats.suspended) const AdminChip('Suspended', tone: ChipTone.danger),
              if (post.authorIsVerified) const AdminChip('Verified', tone: ChipTone.ok),
              AdminChip('${stats.postsCount} posts'),
              AdminChip('${stats.listingsCount} rooms'),
              AdminChip('${stats.liveStatuses} live statuses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaggedRoomCard extends StatelessWidget {
  const _TaggedRoomCard({required this.post});

  final AdminCommunityPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      title: 'Tagged room',
      onTap: () => context.go(Routes.room(post.taggedListingId!)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AdminNetworkImage(
              url: post.taggedListingCoverUrl,
              width: 56,
              height: 56,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.taggedListingTitle ?? 'Room listing',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (post.taggedListingRent != null)
                  Text('₹${post.taggedListingRent} / month', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({
    required this.comments,
    required this.busy,
    required this.onDelete,
    required this.onDismiss,
  });

  final List<AdminCommunityComment> comments;
  final bool busy;
  final void Function(AdminCommunityComment c, int replies) onDelete;
  final ValueChanged<AdminCommunityComment> onDismiss;

  /// Replies under [index] (the next comments that are deeper than it).
  int _repliesUnder(int index) {
    final depth = comments[index].depth;
    var n = 0;
    for (var j = index + 1; j < comments.length && comments[j].depth > depth; j++) {
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = context.isPhone ? 14.0 : 24.0;
    return AdminCard(
      title: 'Comments (${comments.length})',
      subtitle: 'In thread order, as in the app',
      child: comments.isEmpty
          ? Text('No comments yet.', style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in comments.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      left: indent * c.depth.clamp(0, 3),
                      top: i == 0 ? 0 : 10,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.pendingReports > 0
                            ? BrandColors.dangerBg.withValues(alpha: 0.5)
                            : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: c.depth > 0
                            ? Border(
                                left: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminAvatar(url: c.authorAvatarUrl, name: c.authorName, radius: 16),
                          const SizedBox(width: 10),
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
                                    if (c.byPostAuthor)
                                      const AdminChip('Post author', tone: ChipTone.info),
                                    if (c.pendingReports > 0)
                                      AdminChip(
                                        'Reported · ${c.pendingReports}',
                                        tone: ChipTone.danger,
                                      ),
                                    Text(timeAgo(c.createdAt), style: theme.textTheme.bodySmall),
                                  ],
                                ),
                                if (c.replyToName != null && c.depth > 0)
                                  Text(
                                    'Replying to ${c.replyToName}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 4),
                                SelectableText(c.content, style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${c.likesCount} like${c.likesCount == 1 ? '' : 's'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: theme.colorScheme.error,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: busy
                                          ? null
                                          : () => onDelete(c, _repliesUnder(i)),
                                      child: const Text('Delete'),
                                    ),
                                    if (c.pendingReports > 0)
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: busy ? null : () => onDismiss(c),
                                        child: const Text('Dismiss reports'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
