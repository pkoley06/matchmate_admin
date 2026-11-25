import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/admin_ui.dart';
import '../core/widgets/brand_logo.dart';
import '../features/auth/presentation/admin_auth_controller.dart';
import '../features/dashboard/presentation/dashboard_providers.dart';
import 'theme.dart';

/// One sidebar entry. [branch] is its index in the router's shell branches.
class AdminDestination {
  const AdminDestination({
    required this.branch,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.group,
    this.showsReportsBadge = false,
  });

  final int branch;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Section heading printed above this entry ("MODERATION", …).
  final String? group;
  final bool showsReportsBadge;
}

/// In the same order as the shell branches in router.dart.
const adminDestinations = <AdminDestination>[
  AdminDestination(
    branch: 0,
    label: 'Overview',
    icon: Icons.space_dashboard_outlined,
    activeIcon: Icons.space_dashboard_rounded,
  ),
  AdminDestination(
    branch: 1,
    label: 'Reports',
    icon: Icons.flag_outlined,
    activeIcon: Icons.flag_rounded,
    group: 'MODERATION',
    showsReportsBadge: true,
  ),
  AdminDestination(
    branch: 2,
    label: 'Comments',
    icon: Icons.forum_outlined,
    activeIcon: Icons.forum_rounded,
  ),
  AdminDestination(
    branch: 3,
    label: 'Blocks',
    icon: Icons.block_outlined,
    activeIcon: Icons.block_rounded,
  ),
  AdminDestination(
    branch: 4,
    label: 'Users',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    group: 'CONTENT',
  ),
  AdminDestination(
    branch: 5,
    label: 'Rooms',
    icon: Icons.bed_outlined,
    activeIcon: Icons.bed_rounded,
  ),
  AdminDestination(
    branch: 6,
    label: 'Community',
    icon: Icons.diversity_3_outlined,
    activeIcon: Icons.diversity_3_rounded,
  ),
  AdminDestination(
    branch: 7,
    label: 'Announcements',
    icon: Icons.campaign_outlined,
    activeIcon: Icons.campaign_rounded,
    group: 'APP',
  ),
  AdminDestination(
    branch: 8,
    label: 'Questionnaire',
    icon: Icons.quiz_outlined,
    activeIcon: Icons.quiz_rounded,
  ),
  AdminDestination(
    branch: 9,
    label: 'Branding',
    icon: Icons.palette_outlined,
    activeIcon: Icons.palette_rounded,
  ),
];

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _select(int branch) {
    final shell = widget.navigationShell;
    shell.goBranch(
      branch,
      // Tapping the section you are already in returns to its list
      // (e.g. from a room's page back to all rooms).
      initialLocation: branch == shell.currentIndex,
    );
    // The badge and Overview numbers can go stale; refresh when moving around.
    ref.invalidate(dashboardStatsProvider);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthControllerProvider);
    final displayName = authState is AdminAuthenticated
        ? authState.session.displayName
        : '';
    final pending = ref.watch(pendingReportsCountProvider);
    final width = context.screenWidth;
    final selected = widget.navigationShell.currentIndex;
    void logout() => ref.read(adminAuthControllerProvider.notifier).signOut();

    if (width < AdminBreakpoints.phone) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: 290,
          backgroundColor: BrandColors.plum,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
          ),
          child: _SidebarContent(
            compact: false,
            selected: selected,
            pendingReports: pending,
            displayName: displayName,
            onSelect: _select,
            onLogout: logout,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            _PhoneTopBar(
              title: adminDestinations[selected].label,
              pendingReports: pending,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onReports: () => _select(1),
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    final compact = width < AdminBreakpoints.wide;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: compact ? 80 : 256,
            color: BrandColors.plum,
            child: _SidebarContent(
              compact: compact,
              selected: selected,
              pendingReports: pending,
              displayName: displayName,
              onSelect: _select,
              onLogout: logout,
            ),
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}

/// Plum bar across the top on a phone: menu, logo + section, reports bell.
class _PhoneTopBar extends StatelessWidget {
  const _PhoneTopBar({
    required this.title,
    required this.pendingReports,
    required this.onMenu,
    required this.onReports,
  });

  final String title;
  final int pendingReports;
  final VoidCallback onMenu;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: BrandColors.plum,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded, color: BrandColors.creamText),
              ),
              const BrandMark(size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MateEazy Admin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BrandColors.navLabel,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: BrandColors.creamText,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: pendingReports > 0
                    ? '$pendingReports open reports'
                    : 'Reports',
                onPressed: onReports,
                icon: Badge(
                  isLabelVisible: pendingReports > 0,
                  backgroundColor: BrandColors.coral,
                  textColor: BrandColors.plum,
                  label: Text(pendingReports > 99 ? '99+' : '$pendingReports'),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: BrandColors.creamText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.compact,
    required this.selected,
    required this.pendingReports,
    required this.displayName,
    required this.onSelect,
    required this.onLogout,
    this.onClose,
  });

  final bool compact;
  final int selected;
  final int pendingReports;
  final String displayName;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  /// Shown in the phone drawer.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.isEmpty ? 'A' : displayName[0].toUpperCase();
    final items = <Widget>[];
    for (final d in adminDestinations) {
      if (d.group != null) {
        items.add(
          compact
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Divider(color: BrandColors.plumRaised, height: 1),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                  child: Text(
                    d.group!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: BrandColors.navLabel,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        );
      }
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _NavItem(
            destination: d,
            selected: d.branch == selected,
            compact: compact,
            badge: d.showsReportsBadge ? pendingReports : 0,
            onTap: () => onSelect(d.branch),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 0 : 20, 22, compact ? 0 : 8, 10),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : (onClose != null
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start),
              children: [
                compact
                    ? const Tooltip(
                        message: 'MateEazy Admin',
                        child: BrandMark(size: 34),
                      )
                    // Shrinks rather than overflowing with large text.
                    : const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: BrandLogo(
                            height: 36,
                            showAdminTag: true,
                            textColor: BrandColors.creamText,
                          ),
                        ),
                      ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: BrandColors.navText),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
              children: items,
            ),
          ),
          Container(
            margin: EdgeInsets.all(compact ? 12 : 14),
            padding: EdgeInsets.all(compact ? 4 : 10),
            decoration: BoxDecoration(
              color: BrandColors.plumSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: compact
                ? IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    color: BrandColors.navText,
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
                            color: BrandColors.plum,
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: BrandColors.creamText,
                              ),
                            ),
                            Text(
                              'Administrator',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: BrandColors.navLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Log out',
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        color: BrandColors.navText,
                        onPressed: onLogout,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.badge,
    required this.onTap,
  });

  final AdminDestination destination;
  final bool selected;
  final bool compact;
  final int badge;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final selected = widget.selected;
    final fg = selected ? BrandColors.plum : BrandColors.navText;
    final bg = selected
        ? BrandColors.coral
        : (_hover ? BrandColors.plumSoft : Colors.transparent);
    final badgeText = widget.badge > 99 ? '99+' : '${widget.badge}';

    Widget icon = Icon(selected ? d.activeIcon : d.icon, size: 21, color: fg);
    if (widget.compact && widget.badge > 0) {
      icon = Badge(
        backgroundColor: selected ? BrandColors.plum : BrandColors.coral,
        textColor: selected ? BrandColors.creamText : BrandColors.plum,
        label: Text(badgeText),
        child: icon,
      );
    }

    final item = Semantics(
      button: true,
      selected: selected,
      label: widget.badge > 0 ? '${d.label}, ${widget.badge} open' : d.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: widget.compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                icon,
                if (!widget.compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      d.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? BrandColors.plum : BrandColors.coral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: selected
                              ? BrandColors.creamText
                              : BrandColors.plum,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return widget.compact ? Tooltip(message: d.label, child: item) : item;
  }
}
