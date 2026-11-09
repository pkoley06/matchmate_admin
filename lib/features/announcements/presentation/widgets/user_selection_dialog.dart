import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../users/data/admin_users_api.dart';
import '../../../users/domain/admin_user_models.dart';

class UserSelectionDialog extends ConsumerStatefulWidget {
  const UserSelectionDialog({
    super.key,
    required this.initiallySelected,
  });

  final List<AdminUserSummary> initiallySelected;

  @override
  ConsumerState<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends ConsumerState<UserSelectionDialog> {
  final _searchController = TextEditingController();
  final Map<String, AdminUserSummary> _selected = {};
  List<AdminUserSummary> _users = [];
  bool _loading = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    for (final u in widget.initiallySelected) {
      _selected[u.id] = u;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers([String? query]) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await ref.read(adminUsersApiProvider).getUsers(
            search: query?.trim().isEmpty == true ? null : query?.trim(),
            size: 50,
          );
      if (!mounted) return;
      setState(() {
        _users = page.content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _loadUsers(text);
    });
  }

  void _selectAllVisible() {
    setState(() {
      for (final u in _users) {
        _selected[u.id] = u;
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_search_outlined),
          const SizedBox(width: 8),
          const Text('Select Recipients'),
          const Spacer(),
          Text(
            '${_selected.length} selected',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user by name…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _users.isEmpty ? null : _selectAllVisible,
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Select Visible'),
                ),
                TextButton.icon(
                  onPressed: _selected.isEmpty ? null : _deselectAll,
                  icon: const Icon(Icons.deselect, size: 16),
                  label: const Text('Clear All'),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? Center(child: Text('Error loading users: $_error'))
                  : _loading && _users.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _users.isEmpty
                          ? const Center(child: Text('No users found'))
                          : ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (ctx, i) {
                                final user = _users[i];
                                final isSelected = _selected.containsKey(user.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selected[user.id] = user;
                                      } else {
                                        _selected.remove(user.id);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    backgroundImage: user.avatarUrl != null &&
                                            user.avatarUrl!.isNotEmpty
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child: user.avatarUrl == null ||
                                            user.avatarUrl!.isEmpty
                                        ? Text(
                                            user.fullName.isNotEmpty
                                                ? user.fullName[0].toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user.fullName.isEmpty
                                        ? 'Unnamed User'
                                        : user.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    user.lastKnownLocality ??
                                        (user.isActive
                                            ? 'Active'
                                            : 'Inactive'),
                                  ),
                                  dense: true,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(_selected.values.toList());
          },
          icon: const Icon(Icons.check),
          label: Text('Confirm (${_selected.length})'),
        ),
      ],
    );
  }
}
