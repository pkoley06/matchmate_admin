import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/admin_detail_widgets.dart';
import '../../../../core/widgets/admin_ui.dart';
import '../community_providers.dart';
import '../status_review_dialog.dart';
import 'community_widgets.dart';

/// A user's community posts and statuses, on their profile page.
class UserCommunityCard extends ConsumerWidget {
  const UserCommunityCard({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final posts = ref.watch(userPostsProvider(userId));
    final statuses = ref.watch(userStatusesProvider(userId));

    Widget loading() => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );

    return AdminSectionCard(
      title: 'Community',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Posts (${posts.value?.totalElements ?? '…'})',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          switch (posts) {
            AsyncData(:final value) when value.content.isEmpty => Text(
              'No posts.',
              style: theme.textTheme.bodySmall,
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final p in value.content)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(Routes.communityPost(p.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          PostThumb(post: p, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title.isEmpty ? p.content : p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${p.categoryLabel} · ${timeAgo(p.createdAt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ...postStateChips(p).take(1),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) when !posts.isLoading => Text(
              'Couldn’t load posts: $error',
              style: theme.textTheme.bodySmall,
            ),
            _ => loading(),
          },
          const Divider(height: 28),
          Text(
            'Statuses (${statuses.value?.totalElements ?? '…'})',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          switch (statuses) {
            AsyncData(:final value) when value.content.isEmpty => Text(
              'No statuses.',
              style: theme.textTheme.bodySmall,
            ),
            AsyncData(:final value) => SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: value.content.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = value.content[i];
                  return SizedBox(
                    width: 150 * 9 / 16,
                    child: Semantics(
                      button: true,
                      label: s.isLive ? 'Live status' : 'Expired status',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showStatusReviewDialog(context, statusId: s.id),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              StatusArtwork(
                                mediaUrl: s.mediaUrl,
                                caption: s.caption,
                                backgroundColor: s.backgroundColor,
                                captionSize: 10,
                              ),
                              Positioned(
                                left: 4,
                                top: 4,
                                child: s.isLive
                                    ? const AdminChip('Live', tone: ChipTone.ok)
                                    : const AdminChip('Expired'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            AsyncError(:final error) when !statuses.isLoading => Text(
              'Couldn’t load statuses: $error',
              style: theme.textTheme.bodySmall,
            ),
            _ => loading(),
          },
        ],
      ),
    );
  }
}
