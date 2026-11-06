import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_image.dart';
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
    ref.read(usersControllerProvider.notifier).loadUsers(search: val.trim(), page: 0);
  }

  /// Creates a user, then opens their page.
  Future<void> _showCreateDialog() async {
    final created = await UserFormDialog.show(context);
    if (created == null || !mounted) return;
    ref.read(usersControllerProvider.notifier).loadUsers(page: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User created successfully')),
    );
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse, inspect, and moderate registered users',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by full name...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                        ),
                        onSubmitted: _onSearch,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref
                          .read(usersControllerProvider.notifier)
                          .loadUsers(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error display
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),

            // Content Table
            Expanded(
              child: state.isLoading && state.pageData == null
                  ? const Center(child: CircularProgressIndicator())
                  : (state.pageData == null || state.pageData!.content.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            itemCount: state.pageData!.content.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = state.pageData!.content[index];
                              return ListTile(
                                onTap: () => _openUser(user),
                                leading: AdminAvatar(
                                  url: user.avatarUrl,
                                  name: user.fullName,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName
                                          : 'Unnamed User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (user.gender != null)
                                      Chip(
                                        label: Text(
                                          user.gender!,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    if (user.age != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          '${user.age} yrs',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: theme.colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.lastKnownLocality ?? 'Unknown locality',
                                    ),
                                    const SizedBox(width: 12),
                                    Chip(
                                      label: Text(
                                        user.primaryAuthProvider ?? 'AUTH',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (user.isSuspended) ...[
                                      ActionChip(
                                        avatar: const Icon(Icons.block, size: 14, color: Colors.white),
                                        backgroundColor: Colors.red.shade700,
                                        label: const Text(
                                          'Suspended',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        onPressed: () => _confirmUnsuspend(user),
                                      ),
                                      const SizedBox(width: 8),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(Icons.block_outlined, size: 18, color: Colors.red),
                                        tooltip: 'Suspend user',
                                        onPressed: () => _confirmSuspend(user),
                                      ),
                                    ],
                                    _AccountStatusChip(
                                      status: user.accountStatus,
                                      // A deleted account is terminal; only
                                      // ACTIVE <-> DISABLED can be toggled.
                                      onPressed: user.accountStatus ==
                                              AdminAccountStatus.deleted
                                          ? null
                                          : () => ref
                                              .read(usersControllerProvider.notifier)
                                              .toggleActive(user.id, user.isActive),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      tooltip:
                                          'Open user — photo, details, edit',
                                      onPressed: () => _openUser(user),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 12),

            // Pagination Controls
            if (state.pageData != null && state.pageData!.totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${state.pageData!.page + 1} of ${state.pageData!.totalPages} (${state.pageData!.totalElements} total)',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.pageData!.page > 0
                        ? () => ref
                            .read(usersControllerProvider.notifier)
                            .loadUsers(page: state.pageData!.page - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: !state.pageData!.isLast
                        ? () => ref
                            .read(usersControllerProvider.notifier)
                            .loadUsers(page: state.pageData!.page + 1)
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// ACTIVE / DISABLED / DELETED pill. Pressable only when [onPressed] is set.
class _AccountStatusChip extends StatelessWidget {
  const _AccountStatusChip({required this.status, this.onPressed});

  final AdminAccountStatus status;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      AdminAccountStatus.active => (Icons.check_circle, Colors.green),
      AdminAccountStatus.disabled => (Icons.cancel, Colors.red),
      AdminAccountStatus.deleted => (Icons.delete_forever, Colors.grey),
    };
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.label,
        style: TextStyle(color: color.shade800, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }
}
