import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final messenger = ScaffoldMessenger.of(context);
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
    final error =
        await ref.read(blocksControllerProvider.notifier).remove(block);
    messenger.showSnackBar(SnackBar(content: Text(error ?? 'Block lifted.')));
  }

  static String _when(DateTime? d) =>
      d == null ? '' : d.toLocal().toString().split('.').first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blocksControllerProvider);
    final theme = Theme.of(context);
    final controller = ref.read(blocksControllerProvider.notifier);
    const bold = TextStyle(fontWeight: FontWeight.w600);

    final Widget body;
    if (state.isLoading && state.blocks.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.blocks.isEmpty) {
      body = Center(child: Text(state.error!));
    } else if (state.blocks.isEmpty) {
      body = const Center(
        child: Text(
          'Nobody has blocked anyone yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else {
      body = ListView.separated(
        itemCount: state.blocks.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final b = state.blocks[i];
          return ListTile(
            leading: const Icon(Icons.block),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: b.blockerName, style: bold),
                  const TextSpan(text: '  blocked  '),
                  TextSpan(text: b.blockedName, style: bold),
                ],
              ),
            ),
            subtitle: Text(_when(b.createdAt)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (b.blockedUserTotalBlocks > 1)
                  Chip(
                    label: Text('blocked by ${b.blockedUserTotalBlocks}'),
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _remove(context, ref, b),
                  child: const Text('Lift block'),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                        'Blocked users',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every user-to-user block, newest first. A user blocked by '
                        'many different people is worth a closer look.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => controller.load(page: state.page),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: body,
              ),
            ),
            if (state.totalPages > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.page > 0
                        ? () => controller.load(page: state.page - 1)
                        : null,
                  ),
                  Text('Page ${state.page + 1} of ${state.totalPages}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.page + 1 < state.totalPages
                        ? () => controller.load(page: state.page + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
