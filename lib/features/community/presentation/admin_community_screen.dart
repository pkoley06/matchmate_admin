import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../domain/admin_community_models.dart';
import 'admin_community_controller.dart';

class AdminCommunityScreen extends ConsumerStatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  ConsumerState<AdminCommunityScreen> createState() =>
      _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends ConsumerState<AdminCommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(communityControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Moderation',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Moderate public feed posts, bento discussion prompts, and 24-hour stories.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(communityControllerProvider.notifier).loadAll(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: BrandColors.coral,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: BrandColors.coral,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Community Feed Posts'),
                  Tab(text: 'Active 24h Stories / Statuses'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Views
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Error: ${state.error}'))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _PostsTab(searchController: _searchController),
                            const _StatusesTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  const _PostsTab({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    final posts = state.postsPage?.content ?? const [];
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by post title, content, or author…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            searchController.clear();
                            ref
                                .read(communityControllerProvider.notifier)
                                .setSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                onSubmitted: (val) {
                  ref
                      .read(communityControllerProvider.notifier)
                      .setSearch(val.trim());
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                ref
                    .read(communityControllerProvider.notifier)
                    .setSearch(searchController.text.trim());
              },
              child: const Text('Search'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: posts.isEmpty
              ? const Center(
                  child: Text('No community posts found.'),
                )
              : ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostCard(post: post);
                  },
                ),
        ),
      ],
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final AdminCommunityPost post;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete / Moderate Post',
      message:
          'Are you sure you want to remove "${post.title.isNotEmpty ? post.title : 'this post'}" by ${post.authorName}? It will immediately disappear from the app feed.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (confirmed) {
      await ref
          .read(communityControllerProvider.notifier)
          .deletePost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top author row
            Row(
              children: [
                AdminAvatar(
                  url: post.authorAvatarUrl,
                  name: post.authorName,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (post.authorIsVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: BrandColors.coral,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${post.category} · ${_formatDate(post.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: post.status == 'ACTIVE'
                        ? BrandColors.success.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    post.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: post.status == 'ACTIVE'
                          ? BrandColors.success
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  tooltip: 'Moderate / Delete',
                  onPressed: () => _handleDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title / Prompt
            if (post.title.isNotEmpty) ...[
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: BrandColors.coral,
                ),
                const SizedBox(width: 4),
                Text('${post.likesCount} likes'),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${post.commentsCount} replies'),
                if (post.localityName != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.localityName}${post.city != null ? ', ${post.city}' : ''}',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusesTab extends ConsumerWidget {
  const _StatusesTab();

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    AdminUserStatus status,
  ) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete 24h Story',
      message:
          'Remove this active story by ${status.authorName}? It will immediately disappear for all users.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (confirmed) {
      await ref
          .read(communityControllerProvider.notifier)
          .deleteStatus(status.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    final statuses = state.statusesPage?.content ?? const [];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (statuses.isEmpty) {
      return const Center(child: Text('No active 24-hour stories at this moment.'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final hasMedia =
            status.mediaUrl != null && status.mediaUrl!.isNotEmpty;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          color: scheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media / Text Preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: hasMedia ? Colors.black87 : BrandColors.plumSoft,
                  child: hasMedia
                      ? AdminNetworkImage(url: status.mediaUrl!)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              status.caption ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Info & Actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AdminAvatar(
                          url: status.authorAvatarUrl,
                          name: status.authorName,
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            status.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                          tooltip: 'Delete status',
                          onPressed: () => _handleDelete(context, ref, status),
                        ),
                      ],
                    ),
                    if (hasMedia &&
                        status.caption != null &&
                        status.caption!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        status.caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${status.viewsCount} views',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Expires ${_formatExpire(status.expiresAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatExpire(DateTime expires) {
    final diff = expires.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'in ${diff.inMinutes}m';
  }
}
