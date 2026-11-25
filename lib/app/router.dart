import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/presentation/announcements_screen.dart';
import '../features/auth/presentation/admin_auth_controller.dart';
import '../features/auth/presentation/admin_login_screen.dart';
import '../features/auth/presentation/admin_splash_screen.dart';
import '../features/blocks/presentation/blocks_screen.dart';
import '../features/branding/presentation/branding_screen.dart';
import '../features/comments/presentation/comments_screen.dart';
import '../features/community/presentation/admin_community_screen.dart';
import '../features/community/presentation/community_post_screen.dart';
import '../features/dashboard/presentation/overview_screen.dart';
import '../features/questionnaire/presentation/questionnaire_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/rooms/presentation/room_detail_screen.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../features/users/presentation/user_detail_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'admin_shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const overview = '/overview';
  static const users = '/users';
  static const rooms = '/rooms';
  static const reports = '/reports';
  static const blocks = '/blocks';
  static const comments = '/comments';
  static const community = '/community';
  static const branding = '/branding';
  static const questionnaire = '/questionnaire';
  static const announcements = '/announcements';

  /// One listing's page: photos, details, comments, edit.
  static String room(String id) => '$rooms/$id';

  /// One user's page: photo, details, moderation, their listings.
  static String user(String id) => '$users/$id';

  /// One community post: photos, comments, reports, moderation.
  static String communityPost(String id) => '$community/posts/$id';

  /// Community page opened on the Statuses tab.
  static const communityStatuses = '$community?tab=statuses';
}

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter can't watch Riverpod directly, so we mirror AdminAuthState into a ValueNotifier.
  final authState = ValueNotifier<AdminAuthState>(
    ref.read(adminAuthControllerProvider),
  );
  ref.listen(adminAuthControllerProvider, (_, next) => authState.value = next);
  ref.onDispose(authState.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authState,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      return switch (authState.value) {
        AdminAuthInitializing() => loc == Routes.splash ? null : Routes.splash,
        AdminUnauthenticated() => loc == Routes.login ? null : Routes.login,
        AdminAuthenticated() =>
          (loc == Routes.splash || loc == Routes.login || loc == '/')
              ? Routes.overview
              : null,
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const AdminSplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const AdminLoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        // Same order as adminDestinations in admin_shell.dart.
        branches: [
          _branch(Routes.overview, (_, _) => const OverviewScreen()),
          _branch(Routes.reports, (_, _) => const ReportsScreen()),
          _branch(Routes.comments, (_, _) => const CommentsScreen()),
          _branch(Routes.blocks, (_, _) => const BlocksScreen()),
          _branch(
            Routes.users,
            (_, _) => const UsersScreen(),
            detail: (_, state) {
              // Keyed by id: going from one user straight to another must
              // rebuild the page, not reuse its state.
              final id = state.pathParameters['id']!;
              return UserDetailScreen(key: ValueKey(id), userId: id);
            },
          ),
          _branch(
            Routes.rooms,
            (_, _) => const RoomsScreen(),
            detail: (_, state) {
              final id = state.pathParameters['id']!;
              return RoomDetailScreen(key: ValueKey(id), roomId: id);
            },
          ),
          _branch(
            Routes.community,
            (_, state) => AdminCommunityScreen(
              key: ValueKey(state.uri.queryParameters['tab']),
              initialTab: state.uri.queryParameters['tab'] == 'statuses'
                  ? 1
                  : 0,
            ),
            detailPath: 'posts/:id',
            detail: (_, state) {
              final id = state.pathParameters['id']!;
              return CommunityPostScreen(key: ValueKey(id), postId: id);
            },
          ),
          _branch(Routes.announcements, (_, _) => const AnnouncementsScreen()),
          _branch(Routes.questionnaire, (_, _) => const QuestionnaireScreen()),
          _branch(Routes.branding, (_, _) => const BrandingScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(
  String path,
  GoRouterWidgetBuilder list, {
  GoRouterWidgetBuilder? detail,
  String detailPath = ':id',
}) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: list,
      routes: [
        if (detail != null) GoRoute(path: detailPath, builder: detail),
      ],
    ),
  ],
);
