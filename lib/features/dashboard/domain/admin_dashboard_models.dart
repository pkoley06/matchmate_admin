import '../../community/domain/admin_community_models.dart';
import '../../reports/domain/admin_report_models.dart';
import '../../rooms/domain/admin_room_models.dart';
import '../../users/domain/admin_user_models.dart';

/// GET /api/v1/admin/dashboard/stats (AdminDashboardStatsResponse.java).
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.completedOnboardingUsers,
    required this.totalListings,
    required this.availableListings,
    this.recentUsers = const [],
    this.recentListings = const [],
    this.newUsersThisWeek = 0,
    this.communityPosts = 0,
    this.activeCommunityPosts = 0,
    this.liveStatuses = 0,
    this.liveStatusAuthors = 0,
    this.pendingReports = 0,
    this.newReportsToday = 0,
    this.pendingReportsPreview = const [],
    this.recentPosts = const [],
  });

  final int totalUsers;
  final int activeUsers;
  final int completedOnboardingUsers;
  final int totalListings;
  final int availableListings;
  final List<AdminUserSummary> recentUsers;
  final List<AdminRoomSummary> recentListings;
  final int newUsersThisWeek;
  final int communityPosts;
  final int activeCommunityPosts;
  final int liveStatuses;
  final int liveStatusAuthors;
  final int pendingReports;
  final int newReportsToday;

  /// Newest open reports (at most 6).
  final List<AdminReport> pendingReportsPreview;

  /// Five newest community posts.
  final List<AdminCommunityPost> recentPosts;

  static int _n(Object? v) => (v as num?)?.toInt() ?? 0;

  static List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) =>
      ((v as List<dynamic>?) ?? const [])
          .map((e) => f(e as Map<String, dynamic>))
          .toList();

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        totalUsers: _n(json['totalUsers']),
        activeUsers: _n(json['activeUsers']),
        completedOnboardingUsers: _n(json['completedOnboardingUsers']),
        totalListings: _n(json['totalListings']),
        availableListings: _n(json['availableListings']),
        recentUsers: _list(json['recentUsers'], AdminUserSummary.fromJson),
        recentListings: _list(json['recentListings'], AdminRoomSummary.fromJson),
        newUsersThisWeek: _n(json['newUsersThisWeek']),
        communityPosts: _n(json['communityPosts']),
        activeCommunityPosts: _n(json['activeCommunityPosts']),
        liveStatuses: _n(json['liveStatuses']),
        liveStatusAuthors: _n(json['liveStatusAuthors']),
        pendingReports: _n(json['pendingReports']),
        newReportsToday: _n(json['newReportsToday']),
        pendingReportsPreview: _list(
          json['pendingReportsPreview'],
          AdminReport.fromJson,
        ),
        recentPosts: _list(json['recentPosts'], AdminCommunityPost.fromJson),
      );
}
