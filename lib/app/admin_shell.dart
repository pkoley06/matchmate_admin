import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/brand_logo.dart';
import '../features/auth/presentation/admin_auth_controller.dart';
import 'theme.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.people_outline, active: Icons.people, label: 'Users'),
    (icon: Icons.home_outlined, active: Icons.home, label: 'Rooms'),
    (icon: Icons.flag_outlined, active: Icons.flag, label: 'Reports'),
    (icon: Icons.block_outlined, active: Icons.block, label: 'Blocks'),
    (icon: Icons.forum_outlined, active: Icons.forum, label: 'Comments'),
    (icon: Icons.palette_outlined, active: Icons.palette, label: 'Branding'),
    (icon: Icons.quiz_outlined, active: Icons.quiz, label: 'Questionnaire'),
    (
      icon: Icons.campaign_outlined,
      active: Icons.campaign,
      label: 'Announcements',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthControllerProvider);
    final displayName = authState is AdminAuthenticated
        ? authState.session.displayName
        : '';
    final compact = MediaQuery.sizeOf(context).width < 960;

    void select(int index) => navigationShell.goBranch(
      index,
      // Tapping the section you are already in returns to its list
      // (e.g. from a room's page back to all rooms).
      initialLocation: index == navigationShell.currentIndex,
    );

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            compact: compact,
            selected: navigationShell.currentIndex,
            displayName: displayName,
            onSelect: select,
            onLogout: () =>
                ref.read(adminAuthControllerProvider.notifier).signOut(),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.selected,
    required this.displayName,
    required this.onSelect,
    required this.onLogout,
  });

  final bool compact;
  final int selected;
  final String displayName;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 76.0 : 256.0;
    final initial = displayName.isEmpty ? 'A' : displayName[0].toUpperCase();

    return Container(
      width: width,
      color: BrandColors.plum,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 0 : 24, 28, compact ? 0 : 24, 8),
              child: Align(
                alignment: compact ? Alignment.center : Alignment.centerLeft,
                child: BrandLogo(
                  height: compact ? 30 : 34,
                  showWordmark: !compact,
                  textColor: BrandColors.creamText,
                ),
              ),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ADMIN CONSOLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BrandColors.mutedDark,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
                itemCount: AdminShell._destinations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final d = AdminShell._destinations[i];
                  return _NavItem(
                    icon: i == selected ? d.active : d.icon,
                    label: d.label,
                    selected: i == selected,
                    compact: compact,
                    onTap: () => onSelect(i),
                  );
                },
              ),
            ),
            Container(
              margin: EdgeInsets.all(compact ? 12 : 14),
              padding: EdgeInsets.all(compact ? 6 : 12),
              decoration: BoxDecoration(
                color: BrandColors.plumSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: compact
                  ? IconButton(
                      tooltip: 'Log out',
                      icon: const Icon(Icons.logout, size: 20),
                      color: BrandColors.mutedDark,
                      onPressed: onLogout,
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: BrandColors.coral,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName.isEmpty ? 'Admin' : displayName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: BrandColors.creamText),
                              ),
                              Text(
                                'Administrator',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: BrandColors.mutedDark),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Log out',
                          icon: const Icon(Icons.logout, size: 20),
                          color: BrandColors.mutedDark,
                          onPressed: onLogout,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected ? Colors.white : BrandColors.mutedDark;
    final bg = selected
        ? BrandColors.coral
        : (_hover ? BrandColors.plumSoft : Colors.transparent);

    final item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(widget.icon, size: 21, color: fg),
              if (!widget.compact) ...[
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? Colors.white : BrandColors.creamText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return widget.compact ? Tooltip(message: widget.label, child: item) : item;
  }
}
