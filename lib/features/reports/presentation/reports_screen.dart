import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../community/presentation/community_providers.dart';
import '../domain/admin_report_models.dart';
import 'report_target.dart';
import 'reports_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);
    final controller = ref.read(reportsControllerProvider.notifier);

    return AdminPage(
      title: 'Reports',
      subtitle: 'What people flagged in the app. Open one to see it in context.',
      onRefresh: () => controller.loadReports(page: state.page),
      actions: [
        OutlinedButton.icon(
          onPressed: () => controller.loadReports(page: state.page),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFilterBar<String?>(
            filters: const [
              AdminFilter('PENDING', 'Open'),
              AdminFilter('RESOLVED', 'Resolved'),
              AdminFilter('DISMISSED', 'Dismissed'),
              AdminFilter(null, 'All'),
            ],
            selected: state.statusFilter,
            onSelected: controller.setStatusFilter,
          ),
          const SizedBox(height: 10),
          AdminFilterBar<String?>(
            filters: const [
              AdminFilter(null, 'Everything'),
              AdminFilter('POST', 'Posts'),
              AdminFilter('COMMENT', 'Comments'),
              AdminFilter('STATUS', 'Statuses'),
              AdminFilter('USER', 'Users'),
              AdminFilter('LISTING', 'Rooms'),
            ],
            selected: state.typeFilter,
            onSelected: controller.setTypeFilter,
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            AdminErrorBanner(
              state.error!,
              onRetry: () => controller.loadReports(page: state.page),
            ),
            const SizedBox(height: 12),
          ],
          if (state.isLoading && state.reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.reports.isEmpty)
            AdminEmptyState(
              icon: Icons.verified_outlined,
              title: state.statusFilter == 'PENDING'
                  ? 'No open reports'
                  : 'No reports match these filters',
              message: state.statusFilter == 'PENDING'
                  ? 'Everything people reported has been handled.'
                  : null,
            )
          else
            for (final r in state.reports) ...[
              _ReportCard(report: r),
              const SizedBox(height: 12),
            ],
          AdminPager(
            page: state.page,
            totalPages: state.totalPages,
            totalElements: state.totalElements,
            onPage: (p) => controller.loadReports(page: p),
          ),
        ],
      ),
    );
  }
}

/// One action button on a report card.
typedef _Action = ({
  String action,
  String label,
  String title,
  String message,
  bool danger,
});

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final AdminReport report;

  List<_Action> _actions() {
    final r = report;
    final author = r.reportedUserName ?? 'the author';
    final removable = r.contentAvailable != false;
    return [
      if (r.reportType == 'POST' && removable)
        (
          action: 'CONTENT_REMOVED',
          label: 'Hide post',
          title: 'Hide this post?',
          message:
              'It disappears from the app for everyone. Every open report on '
              'it is closed. You can restore it from Community.',
          danger: true,
        ),
      if (r.reportType == 'COMMENT' && removable)
        (
          action: 'CONTENT_REMOVED',
          label: 'Delete comment',
          title: 'Delete this comment?',
          message: 'The comment and any replies under it are removed for everyone.',
          danger: true,
        ),
      if (r.reportType == 'STATUS' && removable)
        (
          action: 'CONTENT_REMOVED',
          label: 'Remove status',
          title: 'Remove this status?',
          message: 'It disappears for everyone right away.',
          danger: true,
        ),
      if (r.reportType == 'LISTING') ...[
        (
          action: 'LISTING_DELISTED',
          label: 'Delist room',
          title: 'Delist this room?',
          message: 'It is marked unavailable and leaves Discover.',
          danger: false,
        ),
        (
          action: 'LISTING_DELETED',
          label: 'Delete room',
          title: 'Delete this room permanently?',
          message: 'The listing is removed for good.',
          danger: true,
        ),
      ],
      if (r.reportedUserId != null)
        (
          action: 'USER_SUSPENDED',
          label: r.reportType == 'USER' ? 'Suspend user' : 'Suspend $author',
          title: 'Suspend $author?',
          message:
              'They are signed out and can’t use the app until you lift the '
              'suspension from their profile.',
          danger: true,
        ),
      (
        action: 'DISMISSED',
        label: 'Dismiss',
        title: 'Dismiss this report?',
        message: r.isCommunity
            ? 'Nothing changes on the content. Other open reports on the same '
                  'content are dismissed too.'
            : 'No action is taken against what was reported.',
        danger: false,
      ),
    ];
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref, _Action a) async {
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(a.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(a.message),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note for the log (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: a.danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(a.label),
          ),
        ],
      ),
    );
    final note = notes.text.trim();
    notes.dispose();
    if (ok != true) return;
    final success = await ref
        .read(reportsControllerProvider.notifier)
        .resolveReport(report.id, a.action, notes: note.isEmpty ? null : note);
    if (!context.mounted) return;
    if (success) {
      refreshCommunity(ref, postId: report.contextPostId);
      showAdminSnack(context, 'Done');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = report;
    final hasSnapshot =
        r.isCommunity && (r.contentPreview != null || r.contentMediaUrl != null);

    return AdminCard(
      borderColor: r.isPending ? BrandColors.coral.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminChip(r.kindLabel, tone: ChipTone.info),
              AdminChip(humanizeEnum(r.reason), tone: ChipTone.danger),
              switch (r.status) {
                'PENDING' => const AdminChip('Open', tone: ChipTone.warn),
                'DISMISSED' => const AdminChip('Dismissed'),
                _ => AdminChip(
                  r.actionTaken == null ? 'Resolved' : humanizeEnum(r.actionTaken),
                  tone: ChipTone.ok,
                ),
              },
              if (r.contentAvailable == false)
                const AdminChip('Already removed', icon: Icons.delete_outline_rounded),
              Text(
                'By ${r.reporterName} · ${timeAgo(r.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          if (r.isCommunity && r.reportedUserName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Posted by ${r.reportedUserName}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (hasSnapshot) ...[
            const SizedBox(height: 10),
            _Snapshot(report: r),
          ],
          if ((r.details ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Reporter’s note', style: theme.textTheme.labelMedium),
            Text(r.details!.trim(), style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => openReportTarget(context, r),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('Open ${r.kindLabel.toLowerCase()}'),
              ),
              if (r.isPending)
                for (final a in _actions())
                  a.action == 'DISMISSED'
                      ? TextButton(
                          onPressed: () => _confirm(context, ref, a),
                          child: Text(a.label),
                        )
                      : OutlinedButton(
                          style: a.danger
                              ? OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                                  ),
                                )
                              : null,
                          onPressed: () => _confirm(context, ref, a),
                          child: Text(a.label),
                        ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The copy of the reported text/photo saved when the report was made.
class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.report});

  final AdminReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = report.contentMediaUrl;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImageUrl(media)) ...[
            GestureDetector(
              onTap: () => showImageViewer(context, [media!]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AdminNetworkImage(url: media, width: 72, height: 72),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              (report.contentPreview ?? '').trim().isEmpty
                  ? '(photo only)'
                  : report.contentPreview!.trim(),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
