import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/uploads/admin_upload_api.dart';
import '../../users/domain/admin_user_models.dart';
import '../domain/admin_announcement_models.dart';
import 'announcements_controller.dart';
import 'widgets/user_selection_dialog.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();
  final _routeController = TextEditingController(text: '/home');

  bool _targetAllUsers = true;
  final Map<String, AdminUserSummary> _selectedUsers = {};

  bool _sending = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  void _applyPreset(String title, String bodySuggestion, {String? route}) {
    setState(() {
      _titleController.text = title;
      if (_bodyController.text.trim().isEmpty ||
          _bodyController.text.contains('MateEazy') ||
          _bodyController.text.contains('update') ||
          _bodyController.text.contains('festival')) {
        _bodyController.text = bodySuggestion;
      }
      if (route != null) {
        _routeController.text = route;
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ref.read(imagePickerProvider).pick();
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploadingImage = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref
          .read(adminUploadApiProvider)
          .uploadBrandingImage(picked.first, BrandingImageKind.splash);
      if (!mounted) return;
      setState(() => _imageController.text = url);
      messenger.showSnackBar(
        const SnackBar(content: Text('Event image uploaded successfully')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickRecipients() async {
    final result = await showDialog<List<AdminUserSummary>>(
      context: context,
      builder: (ctx) => UserSelectionDialog(
        initiallySelected: _selectedUsers.values.toList(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedUsers.clear();
        for (final u in result) {
          _selectedUsers[u.id] = u;
        }
      });
    }
  }

  Future<void> _confirmAndSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_targetAllUsers && _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one recipient user.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final routeText = _routeController.text.trim();
    final titleText = _titleController.text.trim();
    final bodyText = _bodyController.text.trim();
    final isAppUpdate = routeText.contains('play.google.com') ||
        routeText.contains('market://') ||
        titleText.toLowerCase().contains('update') ||
        bodyText.toLowerCase().contains('update');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isAppUpdate
                  ? Icons.system_update_rounded
                  : (_targetAllUsers ? Icons.campaign : Icons.person_search),
              color: isAppUpdate ? Colors.deepPurple : Colors.amber,
            ),
            const SizedBox(width: 8),
            Text(
              _targetAllUsers
                  ? 'Broadcast to All Users'
                  : 'Send to ${_selectedUsers.length} Selected User(s)',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAppUpdate) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'App Update Mode: Tapping notification will open Google Play Store directly!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              _targetAllUsers
                  ? 'This will send an in-app notification and push alert to ALL registered users immediately.'
                  : 'This will send an in-app notification and push alert to ${_selectedUsers.length} selected user(s).',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (!_targetAllUsers) ...[
              const SizedBox(height: 8),
              Text(
                'Recipients: ${_selectedUsers.values.map((u) => u.fullName).take(4).join(", ")}${_selectedUsers.length > 4 ? '... and ${_selectedUsers.length - 4} more' : ''}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Text('Title: $titleText',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Message: $bodyText'),
            const SizedBox(height: 4),
            Text('Target Route: ${routeText.isEmpty ? '/home' : routeText}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            if (_imageController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Includes Event Banner Image: Yes',
                  style: TextStyle(color: Colors.green)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: Icon(
              _targetAllUsers ? Icons.campaign_rounded : Icons.send_rounded,
            ),
            label: Text(
              _targetAllUsers
                  ? 'Broadcast to All'
                  : 'Send to ${_selectedUsers.length} User(s)',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);

    final wasBroadcast = _targetAllUsers;
    final recipientCount = _selectedUsers.length;

    final success = await ref
        .read(announcementsControllerProvider.notifier)
        .broadcast(
          AdminAnnouncementBroadcastRequest(
            title: titleText,
            body: bodyText,
            imageUrl: _imageController.text.trim(),
            actionRoute: routeText.isEmpty ? '/home' : routeText,
            type: isAppUpdate ? 'APP_UPDATE' : null,
            broadcastAll: _targetAllUsers,
            userIds: _targetAllUsers ? null : _selectedUsers.keys.toList(),
          ),
        );

    if (!mounted) return;
    setState(() => _sending = false);

    if (success) {
      _titleController.clear();
      _bodyController.clear();
      _imageController.clear();
      _routeController.text = '/home';
      setState(() {
        _selectedUsers.clear();
        _targetAllUsers = true;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(wasBroadcast
              ? 'Event successfully broadcast to all users!'
              : 'Event notification sent to $recipientCount selected user(s)!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to broadcast event. Check server logs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announcementsAsync = ref.watch(announcementsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements & Festive Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh list',
            onPressed: () =>
                ref.read(announcementsControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Event Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.celebration_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send Festive Event / Announcement',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _targetAllUsers
                                    ? 'Broadcast greetings, events or offers to all users with or without an image.'
                                    : 'Send event or announcement to ${_selectedUsers.length} selected user(s).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target Audience Selector
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _targetAllUsers
                                        ? Icons.groups_outlined
                                        : Icons.person_search_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Target Audience',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!_targetAllUsers)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_selectedUsers.length} selected',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: true,
                                    icon: Icon(Icons.groups_outlined),
                                    label:
                                        Text('All Active Users (Broadcast)'),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    icon: Icon(Icons.person_outline),
                                    label: Text('Selected Users Only'),
                                  ),
                                ],
                                selected: {_targetAllUsers},
                                onSelectionChanged: (val) {
                                  setState(() {
                                    _targetAllUsers = val.first;
                                  });
                                },
                              ),
                              if (!_targetAllUsers) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickRecipients,
                                      icon: const Icon(
                                        Icons.person_add_alt_1_outlined,
                                      ),
                                      label: Text(
                                        _selectedUsers.isEmpty
                                            ? 'Choose Specific Users…'
                                            : 'Add / Change Users (${_selectedUsers.length})',
                                      ),
                                    ),
                                    if (_selectedUsers.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      TextButton(
                                        onPressed: () => setState(
                                          () => _selectedUsers.clear(),
                                        ),
                                        child: const Text('Clear All'),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_selectedUsers.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No users selected yet. Click "Choose Specific Users…" to pick recipients.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedUsers.values.map((u) {
                                      return InputChip(
                                        avatar: CircleAvatar(
                                          backgroundImage: u.avatarUrl !=
                                                      null &&
                                                  u.avatarUrl!.isNotEmpty
                                              ? NetworkImage(u.avatarUrl!)
                                              : null,
                                          child: u.avatarUrl == null ||
                                                  u.avatarUrl!.isEmpty
                                              ? Text(
                                                  u.fullName.isNotEmpty
                                                      ? u.fullName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                )
                                              : null,
                                        ),
                                        label: Text(
                                          u.fullName.isEmpty
                                              ? 'Unnamed'
                                              : u.fullName,
                                        ),
                                        onDeleted: () {
                                          setState(() =>
                                              _selectedUsers.remove(u.id));
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Text('🚀'),
                            label: const Text('App Update (Play Store)'),
                            onPressed: () => _applyPreset(
                              '🚀 New Update Available on Google Play!',
                              'A new version of MateEazy is available on Google Play with new features, performance improvements, and bug fixes. Tap here to update now! 📲',
                              route:
                                  'https://play.google.com/store/apps/details?id=com.mateeazy.app',
                            ),
                          ),
                          ActionChip(
                            avatar: const Text('🪔'),
                            label: const Text('Diwali Greeting'),
                            onPressed: () => _applyPreset(
                              '🪔 Happy Diwali from MateEazy!',
                              'Wishing you and your flatmates a bright and joyous Diwali filled with peace, light, and prosperity! ✨',
                            ),
                          ),
                          ActionChip(
                            avatar: const Text('🎉'),
                            label: const Text('New Year'),
                            onPressed: () => _applyPreset(
                              '🎉 Happy New Year!',
                              'Cheers to new beginnings, new flatmates, and dream homes! Have a wonderful year ahead. 🥂',
                            ),
                          ),
                          ActionChip(
                            avatar: const Text('🎨'),
                            label: const Text('Holi Festival'),
                            onPressed: () => _applyPreset(
                              '🎨 Happy Holi!',
                              'Wishing you a vibrant festival of colours and joy with your loved ones! 🌈',
                            ),
                          ),
                          ActionChip(
                            avatar: const Text('📢'),
                            label: const Text('App Announcement'),
                            onPressed: () => _applyPreset(
                              '📢 New Feature Update',
                              'We have released exciting new updates to help you find the best rooms and flatmates faster!',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          hintText: 'e.g. 🪔 Happy Diwali from MateEazy!',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Body
                      TextFormField(
                        controller: _bodyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message Body *',
                          hintText:
                              'Write your festive wishes, message, or announcement details...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Message body is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Image Upload / URL
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageController,
                              decoration: const InputDecoration(
                                labelText: 'Event Image URL (Optional)',
                                hintText:
                                    'Paste an image URL or use the upload button',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.image_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: _uploadingImage
                                  ? null
                                  : _pickAndUploadImage,
                              icon: _uploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Upload Image'),
                            ),
                          ),
                        ],
                      ),
                      if (_imageController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Image.network(
                                _imageController.text.trim(),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Text('Invalid image URL'),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton.filled(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setState(() => _imageController.clear()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Route
                      TextFormField(
                        controller: _routeController,
                        decoration: const InputDecoration(
                          labelText: 'Deep-Link Route or URL (Optional)',
                          hintText: 'e.g. https://play.google.com/store/apps/details?id=com.mateeazy.app or /home',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.shop_outlined, size: 16),
                            label: const Text('Play Store Link'),
                            onPressed: () => setState(() => _routeController.text =
                                'https://play.google.com/store/apps/details?id=com.mateeazy.app'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.home_outlined, size: 16),
                            label: const Text('/home'),
                            onPressed: () =>
                                setState(() => _routeController.text = '/home'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.notifications_outlined, size: 16),
                            label: const Text('/notifications'),
                            onPressed: () => setState(
                                () => _routeController.text = '/notifications'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Send Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _sending ? null : _confirmAndSend,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _targetAllUsers
                                      ? Icons.campaign_rounded
                                      : Icons.send_rounded,
                                ),
                          label: Text(_sending
                              ? (_targetAllUsers
                                  ? 'Broadcasting to all users…'
                                  : 'Sending to ${_selectedUsers.length} user(s)…')
                              : (_targetAllUsers
                                  ? 'Broadcast Event to All Users'
                                  : 'Send Event to ${_selectedUsers.length} Selected User(s)')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // History Section
            Text(
              'Broadcast History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            announcementsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading history: $err'),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No events or announcements broadcast yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.imageUrl != null &&
                                item.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.celebration,
                                  color:
                                      theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        avatar: const Icon(Icons.people,
                                            size: 14),
                                        label: Text(
                                            '${item.recipientsCount} users'),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sent: ${item.createdAt.toLocal().toString().split('.').first}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
