import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../community/domain/admin_community_models.dart';
import '../../community/presentation/widgets/community_widgets.dart';
import '../../reports/domain/admin_report_models.dart';
import '../../reports/presentation/report_target.dart';
import '../domain/admin_dashboard_models.dart';
import 'dashboard_providers.dart';

/// First page after login: the numbers, what needs a decision, latest posts.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final now = DateTime.now();
    final today =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    Future<void> refresh() => ref.refresh(dashboardStatsProvider.future);

    return AdminPage(
      title: 'Overview',
      subtitle: '$today · what needs you today',
      onRefresh: refresh,
      actions: [
        OutlinedButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: switch (stats) {
        AsyncData(:final value) => _OverviewBody(stats: value),
        AsyncError(:final error) when !stats.isLoading => AdminErrorState(
          '$error',
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.stats});

  final AdminDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      AdminStatTile(
        label: 'Users',
        value: _fmt(stats.totalUsers),
        note: '+${stats.newUsersThisWeek} this week',
        noteColor: BrandColors.okInk,
        onTap: () => context.go(Routes.users),
      ),
      AdminStatTile(
        label: 'Rooms listed',
        value: _fmt(stats.totalListings),
        note: '${_fmt(stats.availableListings)} available',
        onTap: () => context.go(Routes.rooms),
      ),
      AdminStatTile(
        label: 'Community posts',
        value: _fmt(stats.communityPosts),
        note: '${_fmt(stats.activeCommunityPosts)} visible in the app',
        onTap: () => context.go(Routes.community),
      ),
      AdminStatTile(
        label: 'Live statuses',
        value: _fmt(stats.liveStatuses),
        note: stats.liveStatusAuthors == 1
            ? 'from 1 person'
            : 'from ${stats.liveStatusAuthors} people',
        onTap: () => context.go(Routes.communityStatuses),
      ),
      AdminStatTile(
        label: 'Open reports',
        value: _fmt(stats.pendingReports),
        note: '${stats.newReportsToday} new today',
        noteColor: stats.pendingReports > 0 ? BrandColors.dangerInk : null,
        highlight: stats.pendingReports > 0,
        onTap: () => context.go(Routes.reports),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1050 ? 5 : (c.maxWidth >= 640 ? 3 : 2);
        const gap = 12.0;
        final tileWidth = (c.maxWidth - gap * (cols - 1)) / cols;
        final twoColumns = c.maxWidth >= 900;
        final attention = _NeedsAttention(reports: stats.pendingReportsPreview);
        final posts = _LatestPosts(posts: stats.recentPosts);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in tiles) SizedBox(width: tileWidth, child: t),
              ],
            ),
            const SizedBox(height: 18),
            if (twoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: attention),
                  const SizedBox(width: 16),
                  Expanded(child: posts),
                ],
              )
            else ...[
              attention,
              const SizedBox(height: 16),
              posts,
            ],
          ],
        );
      },
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.reports});

  final List<AdminReport> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      title: 'Needs attention',
      subtitle: 'Open reports, newest first',
      trailing: TextButton(
        onPressed: () => context.go(Routes.reports),
        child: const Text('All reports'),
      ),
      child: reports.isEmpty
          ? const AdminEmptyState(
              icon: Icons.verified_outlined,
              title: 'Nothing waiting',
              message: 'No open reports right now.',
            )
          : Column(
              children: [
                for (final r in reports)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openReportTarget(context, r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 74,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AdminChip(r.kindLabel, tone: ChipTone.info),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.headline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  'By ${r.reporterName} · ${timeAgo(r.createdAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminChip(
                            humanizeEnum(r.reason),
                            tone: ChipTone.danger,
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

class _LatestPosts extends StatelessWidget {
  const _LatestPosts({required this.posts});

  final List<AdminCommunityPost> posts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      title: 'Latest community posts',
      trailing: TextButton(
        onPressed: () => context.go(Routes.community),
        child: const Text('Open Community'),
      ),
      child: posts.isEmpty
          ? const AdminEmptyState(
              icon: Icons.diversity_3_outlined,
              title: 'No posts yet',
            )
          : Column(
              children: [
                for (final p in posts)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(Routes.communityPost(p.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          PostThumb(post: p, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title.isEmpty ? p.content : p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  '${p.authorName} · ${p.categoryLabel} · '
                                  '${timeAgo(p.createdAt)} · '
                                  '${p.commentsCount} comments',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (p.isFlagged) ...[
                            const SizedBox(width: 8),
                            const AdminChip('Flagged', tone: ChipTone.warn),
                          ] else if (!p.isActive) ...[
                            const SizedBox(width: 8),
                            const AdminChip('Hidden'),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
