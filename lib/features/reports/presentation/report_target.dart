import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../community/presentation/status_review_dialog.dart';
import '../domain/admin_report_models.dart';

/// Opens whatever a report is about: the post page (for post and comment
/// reports), the status viewer, the user's page or the room's page.
void openReportTarget(BuildContext context, AdminReport r) {
  switch (r.reportType) {
    case 'POST' || 'COMMENT':
      final postId = r.contextPostId ?? r.reportedPostId;
      if (postId != null) {
        context.go(Routes.communityPost(postId));
      } else {
        showAdminSnack(context, 'That post no longer exists.');
      }
    case 'STATUS':
      showStatusReviewDialog(context, statusId: r.reportedStatusId, report: r);
    case 'LISTING':
      if (r.reportedListingId != null) {
        context.go(Routes.room(r.reportedListingId!));
      }
    default:
      if (r.reportedUserId != null) context.go(Routes.user(r.reportedUserId!));
  }
}

/// Reports shown on a post or status page: reason, who, when, outcome.
class ReportList extends StatelessWidget {
  const ReportList({super.key, required this.reports, this.showKind = false});

  final List<AdminReport> reports;

  /// Shows "Post"/"Comment" on each row (a post page lists both).
  final bool showKind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (reports.isEmpty) {
      return Text(
        'No one has reported this.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in reports.indexed) ...[
          if (i > 0) const Divider(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminChip(humanizeEnum(r.reason), tone: ChipTone.danger),
                  if (showKind) AdminChip(r.kindLabel, tone: ChipTone.info),
                  r.isPending
                      ? const AdminChip('Open', tone: ChipTone.warn)
                      : AdminChip(
                          r.actionTaken == null
                              ? humanizeEnum(r.status)
                              : humanizeEnum(r.actionTaken),
                          tone: r.status == 'DISMISSED'
                              ? ChipTone.neutral
                              : ChipTone.ok,
                        ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'By ${r.reporterName} · ${timeAgo(r.createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
              if (showKind && r.reportType == 'COMMENT' && r.contentPreview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '“${r.contentPreview}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if ((r.details ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r.details!.trim(), style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
