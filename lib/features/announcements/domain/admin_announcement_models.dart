class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionRoute = '/home',
    this.recipientsCount = 0,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String actionRoute;
  final int recipientsCount;
  final DateTime createdAt;

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) =>
      AdminAnnouncement(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        actionRoute: json['actionRoute'] as String? ?? '/home',
        recipientsCount: (json['recipientsCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class AdminAnnouncementBroadcastRequest {
  const AdminAnnouncementBroadcastRequest({
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionRoute = '/home',
    this.type,
    this.broadcastAll = true,
    this.userIds,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final String actionRoute;
  final String? type;
  final bool broadcastAll;
  final List<String>? userIds;

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        if (imageUrl != null && imageUrl!.trim().isNotEmpty)
          'imageUrl': imageUrl!.trim(),
        'actionRoute': actionRoute,
        if (type != null && type!.trim().isNotEmpty) 'type': type!.trim(),
        'broadcastAll': broadcastAll,
        if (userIds != null) 'userIds': userIds,
      };
}
