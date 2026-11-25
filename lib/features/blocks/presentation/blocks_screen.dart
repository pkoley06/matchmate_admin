import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/admin_ui.dart';
import '../data/admin_blocks_api.dart';
import 'blocks_controller.dart';

/// Who has blocked whom. A user blocked by several different people stands
/// out via the "blocked by N" badge.
class BlocksScreen extends ConsumerWidget {
  const BlocksScreen({super.key});

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    AdminBlock block,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lift this block?'),
        content: Text(
          '${block.blockerName} will be able to see and message '
          '${block.blockedName} again. The blocker is not notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lift block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref
        .read(blocksControllerProvider.notifier)
        .remove(block);
    if (context.mounted) {
      showAdminSnack(context, error ?? 'Block lifted.', error: error != null);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blocksControllerProvider);
    final theme = Theme.of(context);
    final controller = ref.read(blocksControllerProvider.notifier);
    final bold = theme.textTheme.titleSmall;

    final List<Widget> body;
    if (state.isLoading && state.blocks.isEmpty) {
      body = [
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (state.error != null && state.blocks.isEmpty) {
      body = [
        AdminErrorState(
          state.error!,
          onRetry: () => controller.load(page: state.page),
        ),
      ];
    } else if (state.blocks.isEmpty) {
      body = [
        const AdminEmptyState(
          icon: Icons.block_outlined,
          title: 'Nobody has blocked anyone yet',
        ),
      ];
    } else {
      body = [
        for (final b in state.blocks) ...[
          AdminCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.block_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: b.blockerName, style: bold),
                            const TextSpan(text: '  blocked  '),
                            TextSpan(text: b.blockedName, style: bold),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            timeAgo(b.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (b.blockedUserTotalBlocks > 1)
                            AdminChip(
                              '${b.blockedName} blocked by ${b.blockedUserTotalBlocks}',
                              tone: ChipTone.warn,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _remove(context, ref, b),
                  child: const Text('Lift block'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ];
    }

    return AdminPage(
      title: 'Blocks',
      subtitle:
          'Every user-to-user block, newest first. Someone blocked by many '
          'different people is worth a closer look.',
      onRefresh: () => controller.load(page: state.page),
      actions: [
        OutlinedButton.icon(
          onPressed: () => controller.load(page: state.page),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...body,
          AdminPager(
            page: state.page,
            totalPages: state.totalPages,
            onPage: (p) => controller.load(page: p),
          ),
        ],
      ),
    );
  }
}
