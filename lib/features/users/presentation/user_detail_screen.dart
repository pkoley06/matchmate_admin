import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/uploads/admin_upload_api.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../rooms/data/admin_rooms_repository.dart';
import '../../rooms/domain/admin_room_models.dart';
import '../../rooms/presentation/room_form_dialog.dart';
import '../../rooms/presentation/rooms_controller.dart';
import '../data/admin_users_repository.dart';
import '../domain/admin_user_models.dart';
import 'user_form_dialog.dart';
import 'users_controller.dart';

/// Everything about one user on a single page: their profile photo (view,
/// change, remove), every profile detail (editable), account moderation and
/// the rooms they have listed.
class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  AdminUserDetail? _user;
  bool _loading = true;
  bool _busy = false;
  bool _uploadingPhoto = false;
  String? _error;

  List<AdminRoomSummary> _rooms = [];
  int _roomsTotal = 0;
  bool _roomsLoading = true;
  String? _roomsError;

  AdminUsersRepository get _repo => ref.read(adminUsersRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
    _loadRooms();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _repo.getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _roomsLoading = true;
      _roomsError = null;
    });
    try {
      final page = await ref
          .read(adminRoomsRepositoryProvider)
          .listRooms(hostUserId: widget.userId, size: 50);
      if (!mounted) return;
      setState(() {
        _rooms = page.content;
        _roomsTotal = page.totalElements;
        _roomsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roomsLoading = false;
        _roomsError = e.toString();
      });
    }
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(Routes.users);

  /// Keeps the users list in step with what was changed here.
  void _refreshList() =>
      ref.read(usersControllerProvider.notifier).loadUsers();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs one account change, showing its result and any failure.
  Future<void> _apply(
    Future<AdminUserDetail> Function() change,
    String doneMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await change();
      if (!mounted) return;
      setState(() => _user = updated);
      _refreshList();
      _showMessage(doneMessage);
    } catch (e) {
      _showMessage('Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final user = _user;
    if (user == null) return;
    final saved = await UserFormDialog.show(context, initial: user);
    if (saved == null || !mounted) return;
    setState(() => _user = saved);
    _refreshList();
    _showMessage('Profile updated');
  }

  Future<void> _changePhoto() async {
    final user = _user;
    if (user == null || _uploadingPhoto) return;
    final picked = await ref.read(imagePickerProvider).pick();
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(adminUploadApiProvider)
          .uploadProfilePhoto(picked.first, userId: user.id);
      final updated = await _repo.updateUser(
        user.id,
        AdminUserUpdateRequest(avatarUrl: url),
      );
      if (!mounted) return;
      setState(() => _user = updated);
      _refreshList();
      _showMessage('Profile photo updated');
    } catch (e) {
      _showMessage('Could not change the photo: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final user = _user;
    if (user == null) return;
    final confirmed = await confirmAdminAction(
      context,
      title: 'Remove Profile Photo',
      message:
          "Remove ${user.fullName}'s profile photo? They will show their "
          'initial until a new photo is set.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;
    // An empty value clears the photo on the server.
    await _apply(
      () => _repo.updateUser(
        user.id,
        const AdminUserUpdateRequest(avatarUrl: ''),
      ),
      'Profile photo removed',
    );
  }

  Future<void> _suspend() async {
    final user = _user;
    if (user == null) return;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suspend ${user.fullName}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suspending signs this user out everywhere and blocks them '
                'from using the app.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reason for suspension',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(
              reasonController.text.trim().isEmpty
                  ? 'Suspended by admin'
                  : reasonController.text.trim(),
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _apply(
      () => _repo.setSuspended(user.id, true, reason: reason),
      'User suspended',
    );
  }

  Future<void> _unsuspend() async {
    final user = _user;
    if (user == null) return;
    final confirmed = await confirmAdminAction(
      context,
      title: 'Lift Suspension',
      message: 'Let ${user.fullName} use the app again?',
      confirmLabel: 'Reactivate',
      destructive: false,
    );
    if (!confirmed) return;
    await _apply(
      () => _repo.setSuspended(user.id, false),
      'Suspension lifted',
    );
  }

  Future<void> _toggleActive() async {
    final user = _user;
    if (user == null) return;
    await _apply(
      () => _repo.setActive(user.id, !user.isActive),
      user.isActive ? 'Account disabled' : 'Account re-enabled',
    );
  }

  Future<void> _addRoom() async {
    final user = _user;
    if (user == null) return;
    final created = await RoomFormDialog.show(
      context,
      initialHostUserId: user.id,
      initialHostName: user.fullName,
      initialHostAvatarUrl: user.avatarUrl,
    );
    if (created == null || !mounted) return;
    ref.read(roomsControllerProvider.notifier).loadRooms();
    _loadRooms();
    _showMessage('Listing created');
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, user),
            const SizedBox(height: 16),
            Expanded(
              child: user == null
                  ? Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : AdminErrorBanner(
                              _error ?? 'User not found',
                              onRetry: _load,
                            ),
                    )
                  : _buildBody(context, user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminUserDetail? user) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'Back to users',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user == null
                    ? 'User details'
                    : (user.fullName.isNotEmpty
                          ? user.fullName
                          : 'Unnamed User'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (user != null)
                Text(
                  [
                    if (user.age != null) '${user.age} yrs',
                    if (user.gender != null) humanizeEnum(user.gender),
                    if (user.lastKnownLocality?.isNotEmpty == true)
                      user.lastKnownLocality!,
                  ].join(' • '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (user != null) ...[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading
                ? null
                : () {
                    _load();
                    _loadRooms();
                  },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(BuildContext context, AdminUserDetail user) {
    final photo = _buildPhotoCard(context, user);
    final profile = _buildProfileCard(user);
    final lifestyle = _buildLifestyleCard(user);
    final account = _buildAccountCard(context, user);
    final rooms = _buildRoomsCard(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return ListView(
            children: [
              photo,
              const SizedBox(height: 16),
              profile,
              const SizedBox(height: 16),
              lifestyle,
              const SizedBox(height: 16),
              account,
              const SizedBox(height: 16),
              rooms,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ListView(
                children: [
                  photo,
                  const SizedBox(height: 16),
                  profile,
                  const SizedBox(height: 16),
                  lifestyle,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ListView(
                children: [account, const SizedBox(height: 16), rooms],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCard(BuildContext context, AdminUserDetail user) {
    final theme = Theme.of(context);
    final hasPhoto = isImageUrl(user.avatarUrl);
    return AdminSectionCard(
      title: 'Profile photo',
      child: Row(
        children: [
          InkWell(
            onTap: hasPhoto
                ? () => showImageViewer(context, [user.avatarUrl!])
                : null,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasPhoto
                  ? AdminNetworkImage(
                      key: ValueKey(user.avatarUrl),
                      url: user.avatarUrl,
                      width: 160,
                      height: 160,
                      fallbackIcon: Icons.person_outline,
                    )
                  : SizedBox.square(
                      dimension: 160,
                      child: FittedBox(
                        child: AdminAvatar(url: null, name: user.fullName),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto
                      ? 'Click the photo to see it full size.'
                      : 'This user has no profile photo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _uploadingPhoto || _busy
                          ? null
                          : _changePhoto,
                      icon: _uploadingPhoto
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: Text(
                        _uploadingPhoto
                            ? 'Uploading…'
                            : (hasPhoto ? 'Change photo' : 'Upload photo'),
                      ),
                    ),
                    if (hasPhoto)
                      OutlinedButton.icon(
                        onPressed: _uploadingPhoto || _busy
                            ? null
                            : _removePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AdminUserDetail user) {
    final occupation = [
      if (user.occupationTitle?.trim().isNotEmpty == true)
        user.occupationTitle!.trim(),
      if (user.occupationCategory != null)
        humanizeEnum(user.occupationCategory),
    ].join(' • ');
    return AdminSectionCard(
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminInfoRow('User ID', user.id),
          AdminInfoRow('Full name', user.fullName),
          AdminInfoRow('Gender', humanizeEnum(user.gender)),
          AdminInfoRow(
            'Date of birth',
            user.dateOfBirth == null
                ? '—'
                : '${user.dateOfBirth}'
                      '${user.age != null ? ' (${user.age} yrs)' : ''}',
          ),
          AdminInfoRow('Locality', user.lastKnownLocality ?? '—'),
          AdminInfoRow('Occupation', occupation.isEmpty ? '—' : occupation),
          AdminInfoRow(
            'Bio',
            user.bio?.trim().isNotEmpty == true ? user.bio!.trim() : '—',
          ),
          AdminInfoRow('Email', user.email ?? '—'),
          AdminInfoRow('Phone', user.phoneNumber ?? '—'),
          AdminInfoRow('Signs in with', user.primaryAuthProvider ?? '—'),
          AdminInfoRow('Joined', formatAdminDate(user.createdAt)),
          AdminInfoRow('Last updated', formatAdminDate(user.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildLifestyleCard(AdminUserDetail user) {
    const unanswered = 'Unanswered';
    return AdminSectionCard(
      title: 'Lifestyle answers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminInfoRow(
            'Smoking',
            humanizeEnum(user.smokingHabit, fallback: unanswered),
          ),
          AdminInfoRow(
            'Diet',
            humanizeEnum(user.dietaryPreference, fallback: unanswered),
          ),
          AdminInfoRow(
            'Sleep schedule',
            humanizeEnum(user.sleepSchedule, fallback: unanswered),
          ),
          AdminInfoRow(
            'Cleanliness',
            humanizeEnum(user.cleanlinessLevel, fallback: unanswered),
          ),
          AdminInfoRow(
            'Guests',
            humanizeEnum(user.guestTolerance, fallback: unanswered),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AdminUserDetail user) {
    final theme = Theme.of(context);
    final prefs = user.notificationPreferences;
    final deleted = user.accountStatus == AdminAccountStatus.deleted;
    return AdminSectionCard(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user.isSuspended) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suspended: '
                      '${user.suspendedReason ?? "no reason given"}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          AdminInfoRow(
            'Status',
            '${user.accountStatus.label}'
                '${user.disabledAt != null ? ' since ${formatAdminDate(user.disabledAt)}' : ''}',
          ),
          AdminInfoRow('Onboarding', user.onboardingCompleted ? 'Done' : 'Not finished'),
          AdminInfoRow(
            'Room Finder Mode',
            switch (user.isLookingForRoom) {
              true => 'On (looking for a room)',
              false => 'Off',
              null => 'Unknown',
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.isSuspended)
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _unsuspend,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Lift suspension'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _busy ? null : _suspend,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Suspend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              // A deleted account is terminal; only ACTIVE <-> DISABLED
              // can be toggled.
              if (!deleted)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _toggleActive,
                  icon: Icon(
                    user.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    user.isActive ? 'Disable account' : 'Enable account',
                  ),
                ),
            ],
          ),
          const Divider(height: 28),
          Text(
            'Notification preferences',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Read-only. The user controls these from Settings in the app.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          _PreferenceRow(
            icon: Icons.favorite_border,
            label: 'Likes & Comments',
            value: prefs.likesComments,
          ),
          _PreferenceRow(
            icon: Icons.chat_bubble_outline,
            label: 'Messages & Chat',
            value: prefs.messages,
          ),
          _PreferenceRow(
            icon: Icons.person_search_outlined,
            label: 'Room Seekers Nearby',
            value: prefs.seekersNearby,
          ),
          _PreferenceRow(
            icon: Icons.home_work_outlined,
            label: 'Rooms Listed Nearby',
            value: prefs.roomsNearby,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsCard(BuildContext context) {
    final theme = Theme.of(context);
    return AdminSectionCard(
      title: 'Listings ($_roomsTotal)',
      padding: const EdgeInsets.only(top: 16),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: TextButton.icon(
          onPressed: _addRoom,
          icon: const Icon(Icons.add_home_outlined),
          label: const Text('Add listing'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_roomsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AdminErrorBanner(_roomsError!, onRetry: _loadRooms),
            ),
          if (_roomsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_rooms.isEmpty && _roomsError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Text(
                'This user has not listed any rooms.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final (index, room) in _rooms.indexed) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              onTap: () => context.go(Routes.room(room.id)),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AdminNetworkImage(
                  url: room.photoUrls.isEmpty ? null : room.photoUrls.first,
                  width: 64,
                  height: 48,
                  fallbackIcon: Icons.apartment_outlined,
                ),
              ),
              title: Text(
                room.title.isNotEmpty ? room.title : 'Untitled Listing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (room.placeLabel.isNotEmpty) room.placeLabel,
                  '₹${room.rentAmount ?? 0} / mo',
                  room.isAvailable ? 'Available' : 'Delisted',
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
          if (_roomsTotal > _rooms.length && !_roomsLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Showing the latest ${_rooms.length} of $_roomsTotal.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.outline),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Icon(
            value ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            size: 18,
            color: value ? Colors.green : scheme.outline,
          ),
          const SizedBox(width: 6),
          Text(value ? 'On' : 'Off'),
        ],
      ),
    );
  }
}
