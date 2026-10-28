import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_report_models.dart';
import 'reports_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);
    final theme = Theme.of(context);

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
                        'Reports & Moderation',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review flagged listings and users, enforce platform guidelines, and take action',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref
                      .read(reportsControllerProvider.notifier)
                      .loadReports(page: state.page),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                ChoiceChip(
                  label: const Text('All'),
                  selected: state.statusFilter == null,
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setStatusFilter(null),
                ),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: state.statusFilter == 'PENDING',
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setStatusFilter('PENDING'),
                ),
                ChoiceChip(
                  label: const Text('Resolved'),
                  selected: state.statusFilter == 'RESOLVED',
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setStatusFilter('RESOLVED'),
                ),
                ChoiceChip(
                  label: const Text('Dismissed'),
                  selected: state.statusFilter == 'DISMISSED',
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setStatusFilter('DISMISSED'),
                ),
                const SizedBox(width: 16),
                const Text('Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                ChoiceChip(
                  label: const Text('All'),
                  selected: state.typeFilter == null,
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setTypeFilter(null),
                ),
                ChoiceChip(
                  label: const Text('Users'),
                  selected: state.typeFilter == 'USER',
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setTypeFilter('USER'),
                ),
                ChoiceChip(
                  label: const Text('Listings'),
                  selected: state.typeFilter == 'LISTING',
                  onSelected: (_) => ref
                      .read(reportsControllerProvider.notifier)
                      .setTypeFilter('LISTING'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reports Table
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.reports.isEmpty
                        ? const Center(
                            child: Text(
                              'No reports matching current filters',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.reports.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final report = state.reports[index];
                              return _ReportTile(report: report);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends ConsumerWidget {
  const _ReportTile({required this.report});

  final AdminReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = report.status == 'PENDING';

    final statusColor = switch (report.status) {
      'PENDING' => Colors.orange,
      'RESOLVED' => Colors.green,
      _ => Colors.grey,
    };

    final targetName = report.reportType == 'USER'
        ? (report.reportedUserName ?? 'User #${report.reportedUserId}')
        : (report.reportedListingTitle ?? 'Listing #${report.reportedListingId}');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: report.reportType == 'USER'
                ? Colors.blue.shade100
                : Colors.purple.shade100,
            child: Icon(
              report.reportType == 'USER' ? Icons.person : Icons.home,
              color: report.reportType == 'USER' ? Colors.blue : Colors.purple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.reason,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reported by ${report.reporterName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.reportType}: $targetName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (report.details != null && report.details!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    report.details!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (report.actionTaken != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Action: ${report.actionTaken}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPending) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (report.reportType == 'USER') ...[
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () => _confirmAction(
                      context,
                      ref,
                      'USER_SUSPENDED',
                      'Suspend User ${report.reportedUserName}?',
                      'This will immediately suspend the user account and prevent them from using the app.',
                    ),
                    child: const Text('Suspend User'),
                  ),
                ] else ...[
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                    ),
                    onPressed: () => _confirmAction(
                      context,
                      ref,
                      'LISTING_DELISTED',
                      'Delist this room?',
                      'The room will be marked unavailable and removed from discovery.',
                    ),
                    child: const Text('Delist Room'),
                  ),
                  const SizedBox(height: 6),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: () => _confirmAction(
                      context,
                      ref,
                      'LISTING_DELETED',
                      'Delete this room permanently?',
                      'This listing will be permanently removed.',
                    ),
                    child: const Text('Delete Room'),
                  ),
                ],
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => _confirmAction(
                    context,
                    ref,
                    'DISMISSED',
                    'Dismiss Report?',
                    'No action will be taken against the reported item.',
                  ),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    String title,
    String message,
  ) {
    final notesController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Moderator Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(reportsControllerProvider.notifier)
                  .resolveReport(
                    report.id,
                    action,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Action taken successfully')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
