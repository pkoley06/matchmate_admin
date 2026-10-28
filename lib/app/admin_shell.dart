import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/admin_auth_controller.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.people_outline, label: 'Users'),
    (icon: Icons.home_outlined, label: 'Rooms'),
    (icon: Icons.flag_outlined, label: 'Reports'),
    (icon: Icons.palette_outlined, label: 'Branding'),
    (icon: Icons.quiz_outlined, label: 'Questionnaire'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthControllerProvider);
    final displayName = authState is AdminAuthenticated
        ? authState.session.displayName
        : '';

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.admin_panel_settings, size: 32),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Text(displayName, overflow: TextOverflow.ellipsis),
                      IconButton(
                        tooltip: 'Log out',
                        icon: const Icon(Icons.logout),
                        onPressed: () => ref
                            .read(adminAuthControllerProvider.notifier)
                            .signOut(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
