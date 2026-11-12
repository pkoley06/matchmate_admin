/// One row of the comment moderation log — mirrors AdminCommentResponse.java.
class AdminComment {
  const AdminComment({
    required this.id,
    required this.listingId,
    this.listingTitle,
    this.listingLocality,
    this.listingHostUserId,
    required this.authorUserId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorSuspended = false,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String? listingTitle;
  final String? listingLocality;
  final String? listingHostUserId;
  final String authorUserId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorSuspended;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  /// The comment was left by the room's own host.
  bool get authorIsHost => listingHostUserId == authorUserId;

  factory AdminComment.fromJson(Map<String, dynamic> json) => AdminComment(
        id: json['id'] as String,
        listingId: (json['listingId'] as String?) ?? '',
        listingTitle: json['listingTitle'] as String?,
        listingLocality: json['listingLocality'] as String?,
        listingHostUserId: json['listingHostUserId'] as String?,
        authorUserId: (json['authorUserId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Unknown',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        authorSuspended: json['authorSuspended'] as bool? ?? false,
        content: (json['content'] as String?) ?? '',
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class AdminCommentPage {
  const AdminCommentPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<AdminComment> content;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory AdminCommentPage.fromJson(Map<String, dynamic> json) =>
      AdminCommentPage(
        content: (json['content'] as List<dynamic>? ?? const [])
            .map((e) => AdminComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
        isLast: (json['isLast'] ?? json['last']) as bool? ?? true,
      );
}
