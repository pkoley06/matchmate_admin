import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/admin_auth_controller.dart';
import '../features/auth/presentation/admin_login_screen.dart';
import '../features/auth/presentation/admin_splash_screen.dart';
import '../features/branding/presentation/branding_screen.dart';
import '../features/questionnaire/presentation/questionnaire_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'admin_shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const users = '/users';
  static const rooms = '/rooms';
  static const reports = '/reports';
  static const branding = '/branding';
  static const questionnaire = '/questionnaire';
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
          (loc == Routes.splash || loc == Routes.login) ? Routes.users : null,
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
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.users, builder: (_, _) => const UsersScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.rooms, builder: (_, _) => const RoomsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.reports, builder: (_, _) => const ReportsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.branding,
                builder: (_, _) => const BrandingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.questionnaire,
                builder: (_, _) => const QuestionnaireScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
