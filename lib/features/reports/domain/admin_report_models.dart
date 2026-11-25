/// One report as returned by /api/v1/admin/reports (ReportResponse.java).
class AdminReport {
  const AdminReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reportedUserId,
    this.reportedUserName,
    this.reportedListingId,
    this.reportedListingTitle,
    this.reportedPostId,
    this.reportedPostTitle,
    this.reportedCommentId,
    this.reportedStatusId,
    this.contextPostId,
    this.contentPreview,
    this.contentMediaUrl,
    this.contentAvailable,
    required this.reportType,
    required this.reason,
    this.details,
    required this.status,
    this.actionTaken,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String reporterId;
  final String reporterName;

  /// For POST/COMMENT/STATUS reports this is the author of the content.
  final String? reportedUserId;
  final String? reportedUserName;
  final String? reportedListingId;
  final String? reportedListingTitle;
  final String? reportedPostId;
  final String? reportedPostTitle;
  final String? reportedCommentId;
  final String? reportedStatusId;

  /// The post a POST or COMMENT report belongs to; kept after deletion.
  final String? contextPostId;

  /// Copy of the reported text, taken when the report was made.
  final String? contentPreview;

  /// Copy of the reported photo/status media URL.
  final String? contentMediaUrl;

  /// False once the reported post/comment/status is gone; null for user and
  /// room reports.
  final bool? contentAvailable;

  /// USER, LISTING, POST, COMMENT or STATUS.
  final String reportType;
  final String reason;
  final String? details;

  /// PENDING, RESOLVED or DISMISSED.
  final String status;
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isPending => status == 'PENDING';
  bool get isCommunity =>
      reportType == 'POST' || reportType == 'COMMENT' || reportType == 'STATUS';

  /// "Post", "Comment", "Status", "User", "Room".
  String get kindLabel => switch (reportType) {
    'POST' => 'Post',
    'COMMENT' => 'Comment',
    'STATUS' => 'Status',
    'LISTING' => 'Room',
    _ => 'User',
  };

  /// One line describing what was reported.
  String get headline => switch (reportType) {
    'POST' => reportedPostTitle ?? _firstLine(contentPreview) ?? 'Community post',
    'COMMENT' => '“${_firstLine(contentPreview) ?? 'Comment'}”',
    'STATUS' => 'Status by ${reportedUserName ?? 'someone'}',
    'LISTING' => reportedListingTitle ?? 'Room listing',
    _ => reportedUserName ?? 'User',
  };

  static String? _firstLine(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final line = s.trim().split('\n').first.trim();
    return line.length > 90 ? '${line.substring(0, 90)}…' : line;
  }

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
    id: json['id'] as String,
    reporterId: (json['reporterId'] as String?) ?? '',
    reporterName: (json['reporterName'] as String?) ?? 'Unknown',
    reportedUserId: json['reportedUserId'] as String?,
    reportedUserName: json['reportedUserName'] as String?,
    reportedListingId: json['reportedListingId'] as String?,
    reportedListingTitle: json['reportedListingTitle'] as String?,
    reportedPostId: json['reportedPostId'] as String?,
    reportedPostTitle: json['reportedPostTitle'] as String?,
    reportedCommentId: json['reportedCommentId'] as String?,
    reportedStatusId: json['reportedStatusId'] as String?,
    contextPostId: json['contextPostId'] as String?,
    contentPreview: json['contentPreview'] as String?,
    contentMediaUrl: json['contentMediaUrl'] as String?,
    contentAvailable: json['contentAvailable'] as bool?,
    reportType: (json['reportType'] as String?) ?? 'USER',
    reason: (json['reason'] as String?) ?? 'OTHER',
    details: json['details'] as String?,
    status: (json['status'] as String?) ?? 'PENDING',
    actionTaken: json['actionTaken'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    resolvedAt: json['resolvedAt'] != null
        ? DateTime.tryParse(json['resolvedAt'] as String)
        : null,
  );
}

class AdminReportResolveRequest {
  const AdminReportResolveRequest({required this.action, this.notes});

  /// USER_SUSPENDED, LISTING_DELISTED, LISTING_DELETED, CONTENT_REMOVED or
  /// DISMISSED.
  final String action;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'action': action,
    if (notes != null) 'notes': notes,
  };
}
