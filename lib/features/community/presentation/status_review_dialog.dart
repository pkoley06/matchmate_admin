import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../reports/domain/admin_report_models.dart';
import '../../reports/presentation/report_target.dart';
import '../data/admin_community_api.dart';
import '../domain/admin_community_models.dart';
import 'community_providers.dart';
import 'widgets/community_widgets.dart';

/// Shows one status as it looks in the app, its reports, and Remove /
/// Dismiss. When the status is already gone, shows the copy kept on [report].
Future<void> showStatusReviewDialog(
  BuildContext context, {
  String? statusId,
  AdminReport? report,
}) => showDialog<void>(
  context: context,
  builder: (_) => _StatusReviewDialog(statusId: statusId, report: report),
);

class _StatusReviewDialog extends ConsumerStatefulWidget {
  const _StatusReviewDialog({this.statusId, this.report});

  final String? statusId;
  final AdminReport? report;

  @override
  ConsumerState<_StatusReviewDialog> createState() => _StatusReviewDialogState();
}

class _StatusReviewDialogState extends ConsumerState<_StatusReviewDialog> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      refreshCommunity(ref, statusId: widget.statusId);
      showAdminSnack(context, done);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, '$e', error: true);
    }
  }

  Future<void> _remove(AdminUserStatus s) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Remove this status?',
      message:
          'It disappears for everyone right away and its open reports are '
          'marked as handled. This can’t be undone.',
      confirmLabel: 'Remove status',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminCommunityApiProvider).deleteStatus(s.id),
      'Status removed',
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.statusId;
    final detail = id == null ? null : ref.watch(statusDetailProvider(id));
    final phone = context.isPhone;

    Widget body;
    if (detail == null || (detail.hasError && !detail.isLoading)) {
      body = _Gone(report: widget.report);
    } else if (detail.value == null) {
      body = const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      final d = detail.value!;
      body = _StatusBody(
        detail: d,
        busy: _busy,
        onRemove: () => _remove(d.status),
        onDismiss: () => _run(
          () => ref.read(adminCommunityApiProvider).dismissStatusReports(d.status.id),
          'Reports dismissed',
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.all(phone ? 12 : 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.detail,
    required this.busy,
    required this.onRemove,
    required this.onDismiss,
  });

  final AdminStatusDetail detail;
  final bool busy;
  final VoidCallback onRemove;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = detail.status;
    final theme = Theme.of(context);
    final artwork = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: StatusArtwork(
          mediaUrl: s.mediaUrl,
          caption: s.caption,
          backgroundColor: s.backgroundColor,
          captionSize: 18,
        ),
      ),
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            context.go(Routes.user(s.authorId));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AdminAvatar(url: s.authorAvatarUrl, name: s.authorName, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.authorName, style: theme.textTheme.titleSmall),
                      Text('Open profile', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            s.isLive
                ? AdminChip('Live · ends ${timeLeft(s.expiresAt)}', tone: ChipTone.ok)
                : const AdminChip('Expired'),
            AdminChip('${s.viewsCount} views'),
            if (s.pendingReports > 0)
              AdminChip(
                '${s.pendingReports} open report${s.pendingReports == 1 ? '' : 's'}',
                tone: ChipTone.danger,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Posted ${formatAdminDate(s.createdAt)}', style: theme.textTheme.bodySmall),
        if (isImageUrl(s.mediaUrl) && (s.caption ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(s.caption!.trim(), style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        Text('Reports', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ReportList(reports: detail.reports),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: busy ? null : onRemove,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Remove status'),
        ),
        if (s.pendingReports > 0) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : onDismiss,
            child: const Text('Dismiss reports, keep it'),
          ),
        ],
      ],
    );

    if (context.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: SizedBox(width: 220, child: artwork)),
          const SizedBox(height: 16),
          info,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 280, child: artwork),
        const SizedBox(width: 22),
        Expanded(child: info),
      ],
    );
  }
}

/// The status was deleted (expired statuses are cleaned up) or never loaded.
class _Gone extends StatelessWidget {
  const _Gone({this.report});

  final AdminReport? report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'This status is no longer available.',
          style: theme.textTheme.titleSmall,
        ),
        if (r != null && (r.contentMediaUrl != null || r.contentPreview != null)) ...[
          const SizedBox(height: 6),
          Text(
            'Copy saved when it was reported:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: StatusArtwork(
                    mediaUrl: r.contentMediaUrl,
                    caption: r.contentPreview,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
