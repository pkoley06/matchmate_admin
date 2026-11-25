import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../domain/admin_user_models.dart';
import 'user_form_dialog.dart';
import 'users_controller.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref
        .read(usersControllerProvider.notifier)
        .loadUsers(search: val.trim(), page: 0);
  }

  /// Creates a user, then opens their page.
  Future<void> _showCreateDialog() async {
    final created = await UserFormDialog.show(context);
    if (created == null || !mounted) return;
    ref.read(usersControllerProvider.notifier).loadUsers(page: 0);
    showAdminSnack(context, 'User created successfully');
    context.go(Routes.user(created.id));
  }

  void _openUser(AdminUserSummary user) => context.go(Routes.user(user.id));

  void _confirmSuspend(AdminUserSummary user) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suspend User: ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suspending this user will immediately invalidate their sessions and block them from logging in or using the app.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for suspension *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final reason = reasonController.text.trim().isEmpty
                  ? 'Suspended by admin'
                  : reasonController.text.trim();
              await ref
                  .read(usersControllerProvider.notifier)
                  .toggleSuspend(user.id, user.isSuspended, reason: reason);
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _confirmUnsuspend(AdminUserSummary user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reactivate User: ${user.fullName}'),
        content: const Text(
          'Are you sure you want to lift the suspension on this user account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(usersControllerProvider.notifier)
                  .toggleSuspend(user.id, user.isSuspended);
            },
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersControllerProvider);
    final controller = ref.read(usersControllerProvider.notifier);
    final page = state.pageData;

    return AdminPage(
      title: 'Users',
      subtitle: 'Browse, inspect and moderate everyone signed up',
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Add User'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => controller.loadUsers(),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchField(
                    hint: 'Search by name, email or phone',
                    initialValue: _searchController.text,
                    onSubmitted: (v) {
                      _searchController.text = v;
                      _onSearch(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => controller.loadUsers(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (state.error != null) ...[
              AdminErrorBanner(
                state.error!,
                onRetry: () => controller.loadUsers(),
              ),
              const SizedBox(height: 14),
            ],
            if (state.isLoading && page == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (page == null || page.content.isEmpty)
              const AdminEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No users found',
                message: 'Try another search.',
              )
            else
              for (final user in page.content) ...[
                _UserCard(
                  user: user,
                  onOpen: () => _openUser(user),
                  onSuspend: () => _confirmSuspend(user),
                  onUnsuspend: () => _confirmUnsuspend(user),
                  // A deleted account is terminal; only ACTIVE <-> DISABLED
                  // can be toggled.
                  onToggleActive:
                      user.accountStatus == AdminAccountStatus.deleted
                      ? null
                      : () => controller.toggleActive(user.id, user.isActive),
                ),
                const SizedBox(height: 10),
              ],
            if (page != null)
              AdminPager(
                page: page.page,
                totalPages: page.totalPages,
                totalElements: page.totalElements,
                onPage: (p) => controller.loadUsers(page: p),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// One user: photo, name, where they are, how they sign in, account state.
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onOpen,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onToggleActive,
  });

  final AdminUserSummary user;
  final VoidCallback onOpen;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = adminSignInIdentifier(
      email: user.email,
      phoneNumber: user.phoneNumber,
    );
    final meta = [
      user.lastKnownLocality ?? 'Unknown locality',
      ?id,
    ].join(' · ');
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAvatar(url: user.avatarUrl, name: user.fullName, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Unnamed User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (user.isSuspended)
                      const AdminChip(
                        'Suspended',
                        tone: ChipTone.danger,
                        icon: Icons.block_rounded,
                      ),
                    _AccountStatusChip(status: user.accountStatus),
                    if (user.gender != null)
                      AdminChip(humanizeEnum(user.gender)),
                    if (user.age != null) AdminChip('${user.age} yrs'),
                    AdminChip(
                      user.primaryAuthProvider ?? 'AUTH',
                      tone: ChipTone.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'User actions',
            onSelected: (v) => switch (v) {
              'suspend' => onSuspend(),
              'unsuspend' => onUnsuspend(),
              'toggle' => onToggleActive?.call(),
              _ => onOpen(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'open',
                child: Text('Open user — photo, details, edit'),
              ),
              user.isSuspended
                  ? const PopupMenuItem(
                      value: 'unsuspend',
                      child: Text('Lift suspension'),
                    )
                  : const PopupMenuItem(
                      value: 'suspend',
                      child: Text('Suspend user'),
                    ),
              if (onToggleActive != null)
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    user.isActive ? 'Disable account' : 'Re-activate account',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ACTIVE / DISABLED / DELETED pill.
class _AccountStatusChip extends StatelessWidget {
  const _AccountStatusChip({required this.status});

  final AdminAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (status) {
      AdminAccountStatus.active => (Icons.check_circle_rounded, ChipTone.ok),
      AdminAccountStatus.disabled => (Icons.cancel_rounded, ChipTone.warn),
      AdminAccountStatus.deleted => (
        Icons.delete_forever_rounded,
        ChipTone.neutral,
      ),
    };
    return AdminChip(status.label, tone: tone, icon: icon);
  }
}
