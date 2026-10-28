class AdminReport {
  const AdminReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.reportedUserId,
    this.reportedUserName,
    this.reportedListingId,
    this.reportedListingTitle,
    required this.reportType,
    required this.reason,
    this.details,
    required this.status,
    this.actionTaken,
    required this.createdAt,
    this.resolvedAt,
  });

  final int id;
  final int reporterId;
  final String reporterName;
  final int? reportedUserId;
  final String? reportedUserName;
  final int? reportedListingId;
  final String? reportedListingTitle;
  final String reportType; // 'USER' or 'LISTING'
  final String reason;     // 'SPAM', 'INAPPROPRIATE', 'SCAM', 'HARASSMENT', 'OTHER'
  final String? details;
  final String status;     // 'PENDING', 'RESOLVED', 'DISMISSED'
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: (json['id'] as num).toInt(),
        reporterId: (json['reporterId'] as num).toInt(),
        reporterName: (json['reporterName'] as String?) ?? 'Unknown',
        reportedUserId: (json['reportedUserId'] as num?)?.toInt(),
        reportedUserName: json['reportedUserName'] as String?,
        reportedListingId: (json['reportedListingId'] as num?)?.toInt(),
        reportedListingTitle: json['reportedListingTitle'] as String?,
        reportType: (json['reportType'] as String?) ?? 'USER',
        reason: (json['reason'] as String?) ?? 'OTHER',
        details: json['details'] as String?,
        status: (json['status'] as String?) ?? 'PENDING',
        actionTaken: json['actionTaken'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.tryParse(json['resolvedAt'] as String)
            : null,
      );
}

class AdminReportResolveRequest {
  const AdminReportResolveRequest({
    required this.action,
    this.notes,
  });

  final String action; // 'USER_SUSPENDED', 'LISTING_DELISTED', 'LISTING_DELETED', 'DISMISSED'
  final String? notes;

  Map<String, dynamic> toJson() => {
        'action': action,
        if (notes != null) 'notes': notes,
      };
}
