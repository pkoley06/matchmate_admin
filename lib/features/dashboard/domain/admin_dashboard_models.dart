import '../../rooms/domain/admin_room_models.dart';
import '../../users/domain/admin_user_models.dart';

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.completedOnboardingUsers,
    required this.totalListings,
    required this.availableListings,
    this.recentUsers = const [],
    this.recentListings = const [],
  });

  final int totalUsers;
  final int activeUsers;
  final int completedOnboardingUsers;
  final int totalListings;
  final int availableListings;
  final List<AdminUserSummary> recentUsers;
  final List<AdminRoomSummary> recentListings;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
        completedOnboardingUsers:
            (json['completedOnboardingUsers'] as num?)?.toInt() ?? 0,
        totalListings: (json['totalListings'] as num?)?.toInt() ?? 0,
        availableListings: (json['availableListings'] as num?)?.toInt() ?? 0,
        recentUsers: (json['recentUsers'] as List<dynamic>? ?? [])
            .map((e) => AdminUserSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentListings: (json['recentListings'] as List<dynamic>? ?? [])
            .map((e) => AdminRoomSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
