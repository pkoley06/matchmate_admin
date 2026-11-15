/// Admin models for Community Posts & Statuses moderation.
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
  final String status;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final String? authorOccupation;

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
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
        isPinned: json['isPinned'] as bool? ?? false,
        status: (json['status'] as String?) ?? 'ACTIVE',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        authorId: (json['authorId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Neighbor',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        authorIsVerified: json['authorIsVerified'] as bool? ?? false,
        authorOccupation: json['authorOccupation'] as String?,
      );
}

class AdminCommunityPostPage {
  const AdminCommunityPostPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<AdminCommunityPost> content;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory AdminCommunityPostPage.fromJson(Map<String, dynamic> json) =>
      AdminCommunityPostPage(
        content: ((json['content'] as List<dynamic>?) ?? const [])
            .map((e) => AdminCommunityPost.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        isLast: json['isLast'] as bool? ?? true,
      );
}

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
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? mediaUrl;
  final String? caption;
  final String? backgroundColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewsCount;

  factory AdminUserStatus.fromJson(Map<String, dynamic> json) =>
      AdminUserStatus(
        id: json['id'] as String,
        authorId: (json['authorId'] as String?) ?? '',
        authorName: (json['authorName'] as String?) ?? 'Neighbor',
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        caption: json['caption'] as String?,
        backgroundColor: json['backgroundColor'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      );
}

class AdminUserStatusPage {
  const AdminUserStatusPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<AdminUserStatus> content;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  factory AdminUserStatusPage.fromJson(Map<String, dynamic> json) =>
      AdminUserStatusPage(
        content: ((json['content'] as List<dynamic>?) ?? const [])
            .map((e) => AdminUserStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        isLast: json['isLast'] as bool? ?? true,
      );
}
