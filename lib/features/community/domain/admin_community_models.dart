import '../../reports/domain/admin_report_models.dart';

DateTime _date(Object? v) =>
    DateTime.tryParse(v as String? ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// A community post as the admin sees it (AdminCommunityPostResponse.java:
/// the post's fields plus how many reports are still open on it).
class AdminCommunityPost {
  const AdminCommunityPost({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.priceAmount,
    this.localityName,
    this.city,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    required this.status,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.authorOccupation,
    this.taggedListingId,
    this.taggedListingTitle,
    this.taggedListingRent,
    this.taggedListingCoverUrl,
    this.pendingReports = 0,
  });

  final String id;
  final String category;
  final String title;
  final String content;
  final int? priceAmount;
  final String? localityName;
  final String? city;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;

  /// ACTIVE, ARCHIVED (hidden by an admin or its author) or FLAGGED.
  final String status;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final String? authorOccupation;
  final String? taggedListingId;
  final String? taggedListingTitle;
  final int? taggedListingRent;
  final String? taggedListingCoverUrl;
  final int pendingReports;

  bool get isActive => status == 'ACTIVE';
  bool get isFlagged => pendingReports > 0;

  /// "Marketplace", "Flat tour", …
  String get categoryLabel => communityCategoryLabel(category);

  /// "Salt Lake Sector V, Kolkata"
  String? get place {
    final parts = [localityName, city]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  AdminCommunityPost copyWith({
    bool? isPinned,
    String? status,
    List<String>? imageUrls,
    int? pendingReports,
    int? commentsCount,
  }) => AdminCommunityPost(
    id: id,
    category: category,
    title: title,
    content: content,
    priceAmount: priceAmount,
    localityName: localityName,
    city: city,
    imageUrls: imageUrls ?? this.imageUrls,
    likesCount: likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    isPinned: isPinned ?? this.isPinned,
    status: status ?? this.status,
    createdAt: createdAt,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    authorIsVerified: authorIsVerified,
    authorOccupation: authorOccupation,
    taggedListingId: taggedListingId,
    taggedListingTitle: taggedListingTitle,
    taggedListingRent: taggedListingRent,
    taggedListingCoverUrl: taggedListingCoverUrl,
    pendingReports: pendingReports ?? this.pendingReports,
  );

  factory AdminCommunityPost.fromJson(Map<String, dynamic> json) =>
      AdminCommunityPost(
        id: json['id'] as String,
        category: (json['category'] as String?) ?? 'GENERAL',
        title: (json['title'] as String?) ?? '',
        content: (json['content'] as String?) ?? '',
        priceAmount: (json['priceAmount'] as num?)?.toInt(),
        localityName: json['localityName'] as String?,
        city: json['city'] as String?,
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
        likesCount: _int(json['likesCount']),
        commentsCount: _int(json['commentsCount']),
        isPinned: json['isPinned'] as bool? ?? false,
        status: (json['status'] as String?) ?? 'ACTIVE',
        createdAt: _date(json['createdAt']),
        authorId: (json['authorId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Neighbor',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        authorIsVerified: json['authorIsVerified'] as bool? ?? false,
        authorOccupation: json['authorOccupation'] as String?,
        taggedListingId: json['taggedListingId'] as String?,
        taggedListingTitle: json['taggedListingTitle'] as String?,
        taggedListingRent: (json['taggedListingRent'] as num?)?.toInt(),
        taggedListingCoverUrl: json['taggedListingCoverUrl'] as String?,
        pendingReports: _int(json['pendingReports']),
      );
}

/// Category values and their names in the app (CommunityPostCategory.java).
const communityCategories = {
  'FLAT_TOUR': 'Flat tour',
  'MOVED_IN': 'Moved in!',
  'ADVICE': 'Advice',
  'ASK': 'Ask Locals',
  'MARKETPLACE': 'Buy & Sell',
  'HANGOUT': 'Hangouts',
  'RIDES': 'Rides',
  'VACANCY': 'Room Alert',
  'GENERAL': 'General',
};

String communityCategoryLabel(String category) => switch (category) {
  final c when communityCategories.containsKey(c) => communityCategories[c]!,
  _ =>
    category.isEmpty
        ? 'General'
        : category[0] + category.substring(1).toLowerCase().replaceAll('_', ' '),
};

/// A status (24-hour story) as the admin sees it.
class AdminUserStatus {
  const AdminUserStatus({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.caption,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
    this.pendingReports = 0,
    this.live,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? mediaUrl;
  final String? caption;

  /// "#RRGGBB" behind a text-only status.
  final String? backgroundColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewsCount;
  final int pendingReports;
  /// From the server; null on older servers (then worked out from expiresAt).
  final bool? live;

  /// Still visible in the app (not expired).
  bool get isLive => live ?? expiresAt.isAfter(DateTime.now());

  factory AdminUserStatus.fromJson(Map<String, dynamic> json) =>
      AdminUserStatus(
        id: json['id'] as String,
        authorId: (json['authorId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Neighbor',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        caption: json['caption'] as String?,
        backgroundColor: json['backgroundColor'] as String?,
        createdAt: _date(json['createdAt']),
        expiresAt: _date(json['expiresAt']),
        viewsCount: _int(json['viewsCount']),
        pendingReports: _int(json['pendingReports']),
        live: json['live'] as bool?,
      );
}

/// A comment on a community post (AdminCommunityCommentResponse.java).
class AdminCommunityComment {
  const AdminCommunityComment({
    required this.id,
    required this.postId,
    this.postTitle,
    this.postStatus,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.byPostAuthor = false,
    required this.content,
    this.parentId,
    this.depth = 0,
    this.replyToName,
    this.likesCount = 0,
    this.pendingReports = 0,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String? postTitle;
  final String? postStatus;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool byPostAuthor;
  final String content;
  final String? parentId;
  final int depth;
  final String? replyToName;
  final int likesCount;
  final int pendingReports;
  final DateTime createdAt;

  factory AdminCommunityComment.fromJson(Map<String, dynamic> json) =>
      AdminCommunityComment(
        id: json['id'] as String,
        postId: (json['postId'] as String?) ?? '',
        postTitle: json['postTitle'] as String?,
        postStatus: json['postStatus'] as String?,
        authorId: (json['authorId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Neighbor',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        byPostAuthor: json['byPostAuthor'] as bool? ?? false,
        content: (json['content'] as String?) ?? '',
        parentId: json['parentId'] as String?,
        depth: _int(json['depth']),
        replyToName: json['replyToName'] as String?,
        likesCount: _int(json['likesCount']),
        pendingReports: _int(json['pendingReports']),
        createdAt: _date(json['createdAt']),
      );
}

/// Everything the post page shows.
class AdminPostDetail {
  const AdminPostDetail({
    required this.post,
    this.comments = const [],
    this.reports = const [],
    this.author = const AdminAuthorStats(),
  });

  final AdminCommunityPost post;

  /// In thread order (each reply right after its parent).
  final List<AdminCommunityComment> comments;

  /// Every report about the post or one of its comments, newest first.
  final List<AdminReport> reports;
  final AdminAuthorStats author;

  factory AdminPostDetail.fromJson(Map<String, dynamic> json) =>
      AdminPostDetail(
        post: AdminCommunityPost.fromJson(json['post'] as Map<String, dynamic>),
        comments: ((json['comments'] as List?) ?? const [])
            .map((e) => AdminCommunityComment.fromJson(e as Map<String, dynamic>))
            .toList(),
        reports: ((json['reports'] as List?) ?? const [])
            .map((e) => AdminReport.fromJson(e as Map<String, dynamic>))
            .toList(),
        author: json['author'] is Map<String, dynamic>
            ? AdminAuthorStats.fromJson(json['author'] as Map<String, dynamic>)
            : const AdminAuthorStats(),
      );
}

class AdminAuthorStats {
  const AdminAuthorStats({
    this.postsCount = 0,
    this.liveStatuses = 0,
    this.listingsCount = 0,
    this.suspended = false,
    this.joinedAt,
  });

  final int postsCount;
  final int liveStatuses;
  final int listingsCount;
  final bool suspended;
  final DateTime? joinedAt;

  factory AdminAuthorStats.fromJson(Map<String, dynamic> json) =>
      AdminAuthorStats(
        postsCount: _int(json['postsCount']),
        liveStatuses: _int(json['liveStatuses']),
        listingsCount: _int(json['listingsCount']),
        suspended: json['suspended'] as bool? ?? false,
        joinedAt: json['joinedAt'] == null ? null : _date(json['joinedAt']),
      );
}

class AdminStatusDetail {
  const AdminStatusDetail({required this.status, this.reports = const []});

  final AdminUserStatus status;
  final List<AdminReport> reports;

  factory AdminStatusDetail.fromJson(Map<String, dynamic> json) =>
      AdminStatusDetail(
        status: AdminUserStatus.fromJson(json['status'] as Map<String, dynamic>),
        reports: ((json['reports'] as List?) ?? const [])
            .map((e) => AdminReport.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One page of a Spring list endpoint.
class Paged<T> {
  const Paged({
    this.content = const [],
    this.page = 0,
    this.totalElements = 0,
    this.totalPages = 0,
    this.isLast = true,
  });

  final List<T> content;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory Paged.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) => Paged(
    content: ((json['content'] as List<dynamic>?) ?? const [])
        .map((e) => item(e as Map<String, dynamic>))
        .toList(),
    page: _int(json['page'] ?? json['number']),
    totalElements: _int(json['totalElements']),
    totalPages: _int(json['totalPages']),
    isLast: (json['isLast'] ?? json['last']) as bool? ?? true,
  );
}
