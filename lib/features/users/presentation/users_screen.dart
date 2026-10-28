import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_user_models.dart';
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

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _UserFormDialog(),
    );
  }

  void _showDetailDialog(AdminUserSummary summary) async {
    final detail = await ref
        .read(usersControllerProvider.notifier)
        .fetchDetail(summary.id);
    if (!mounted || detail == null) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => _UserDetailDialog(detail: detail),
    );
  }

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
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  foregroundColor:
                                      theme.colorScheme.onPrimaryContainer,
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                    ActionChip(
                                      avatar: Icon(
                                        user.isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: user.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      label: Text(
                                        user.isActive ? 'Active' : 'Disabled',
                                        style: TextStyle(
                                          color: user.isActive
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () => ref
                                          .read(usersControllerProvider.notifier)
                                          .toggleActive(user.id, user.isActive),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'Inspect details',
                                      onPressed: () => _showDetailDialog(user),
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

class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            child: Text(detail.fullName.isNotEmpty ? detail.fullName[0] : '?'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.fullName),
                Text(
                  'User ID: ${detail.id} • Auth: ${detail.primaryAuthProvider ?? "N/A"}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail.isSuspended)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ACCOUNT SUSPENDED: ${detail.suspendedReason ?? "No reason specified"}',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _infoTile('Gender', detail.gender ?? 'Not specified'),
              _infoTile('Date of Birth', detail.dateOfBirth ?? 'Not specified'),
              _infoTile('Locality', detail.lastKnownLocality ?? 'Not specified'),
              _infoTile('Occupation', '${detail.occupationTitle ?? ""} (${detail.occupationCategory ?? "N/A"})'),
              _infoTile('Bio', detail.bio ?? 'No bio provided'),
              const Divider(height: 24),
              Text(
                'Lifestyle Questionnaire Answers',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _infoTile('Smoking Habit', detail.smokingHabit ?? 'Unanswered'),
              _infoTile('Dietary Preference', detail.dietaryPreference ?? 'Unanswered'),
              _infoTile('Sleep Schedule', detail.sleepSchedule ?? 'Unanswered'),
              _infoTile('Cleanliness Level', detail.cleanlinessLevel ?? 'Unanswered'),
              _infoTile('Guest Tolerance', detail.guestTolerance ?? 'Unanswered'),
              const Divider(height: 24),
              _infoTile('Onboarding Completed', detail.onboardingCompleted ? 'Yes' : 'No'),
              _infoTile('Status', detail.isActive ? 'Active' : 'Disabled'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UserFormDialog extends ConsumerStatefulWidget {
  const _UserFormDialog();

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _localityController = TextEditingController();
  final _dobController = TextEditingController(text: '1998-05-15');
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();

  String _gender = 'MALE';
  String _smoking = 'NON_SMOKER';
  String _diet = 'VEGETARIAN';
  String _sleep = 'FLEXIBLE';
  String _cleanliness = 'MODERATE';
  String _guest = 'OCCASIONAL';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _localityController.dispose();
    _dobController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final success = await ref.read(usersControllerProvider.notifier).createUser(
          AdminUserCreateRequest(
            fullName: _nameController.text.trim(),
            gender: _gender,
            dateOfBirth: _dobController.text.trim(),
            lastKnownLocality: _localityController.text.trim(),
            occupationTitle: _occupationController.text.trim(),
            bio: _bioController.text.trim(),
            smokingHabit: _smoking,
            dietaryPreference: _diet,
            sleepSchedule: _sleep,
            cleanlinessLevel: _cleanliness,
            guestTolerance: _guest,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'NON_BINARY', child: Text('Non-Binary')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD) *',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _localityController,
                  decoration: const InputDecoration(labelText: 'Locality / Area'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _occupationController,
                  decoration: const InputDecoration(labelText: 'Occupation Title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Lifestyle Answers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _smoking,
                  decoration: const InputDecoration(labelText: 'Smoking Habit'),
                  items: const [
                    DropdownMenuItem(value: 'NON_SMOKER', child: Text('Non-smoker')),
                    DropdownMenuItem(value: 'OCCASIONAL_SMOKER', child: Text('Occasional / Balcony')),
                    DropdownMenuItem(value: 'REGULAR_SMOKER', child: Text('Regular smoker')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _smoking = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _diet,
                  decoration: const InputDecoration(labelText: 'Dietary Preference'),
                  items: const [
                    DropdownMenuItem(value: 'VEGETARIAN', child: Text('Vegetarian')),
                    DropdownMenuItem(value: 'NON_VEGETARIAN', child: Text('Non-Vegetarian')),
                    DropdownMenuItem(value: 'VEGAN', child: Text('Vegan')),
                    DropdownMenuItem(value: 'EGGETARIAN', child: Text('Eggetarian')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _diet = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _cleanliness,
                  decoration: const InputDecoration(labelText: 'Cleanliness'),
                  items: const [
                    DropdownMenuItem(value: 'VERY_CLEAN', child: Text('Very Clean')),
                    DropdownMenuItem(value: 'MODERATE', child: Text('Moderate')),
                    DropdownMenuItem(value: 'RELAXED', child: Text('Relaxed')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _cleanliness = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sleep,
                  decoration: const InputDecoration(labelText: 'Sleep Schedule'),
                  items: const [
                    DropdownMenuItem(value: 'EARLY_BIRD', child: Text('Early Bird')),
                    DropdownMenuItem(value: 'FLEXIBLE', child: Text('Flexible')),
                    DropdownMenuItem(value: 'NIGHT_OWL', child: Text('Night Owl')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sleep = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _guest,
                  decoration: const InputDecoration(labelText: 'Guest Tolerance'),
                  items: const [
                    DropdownMenuItem(value: 'NO_GUESTS', child: Text('No Guests')),
                    DropdownMenuItem(value: 'OCCASIONAL', child: Text('Occasional Guests')),
                    DropdownMenuItem(value: 'FREQUENT', child: Text('Frequent Guests')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _guest = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }
}
