import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../comments/presentation/room_comments_panel.dart';
import '../data/admin_rooms_repository.dart';
import '../domain/admin_room_models.dart';
import 'room_form_dialog.dart';
import 'rooms_controller.dart';

/// Everything about one listing on a single page: its photos, every detail,
/// the host, and the comments left on it — with edit, delist and delete.
class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  AdminRoomDetail? _room;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final room = await ref
          .read(adminRoomsRepositoryProvider)
          .getRoom(widget.roomId);
      if (!mounted) return;
      setState(() {
        _room = room;
        _photoIndex = 0;
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

  void _back() => context.canPop() ? context.pop() : context.go(Routes.rooms);

  /// Keeps the rooms list in step with what was changed here.
  void _refreshList() => ref.read(roomsControllerProvider.notifier).loadRooms();

  void _showMessage(String message) {
    if (!mounted) return;
    showAdminSnack(context, message);
  }

  Future<void> _edit() async {
    final room = _room;
    if (room == null) return;
    final saved = await RoomFormDialog.show(context, initial: room);
    if (saved == null || !mounted) return;
    setState(() {
      _room = saved;
      _photoIndex = 0;
    });
    _refreshList();
    _showMessage('Listing updated');
  }

  Future<void> _toggleAvailable() async {
    final room = _room;
    if (room == null || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(adminRoomsRepositoryProvider)
          .setAvailable(room.id, !room.isAvailable);
      if (!mounted) return;
      setState(() => _room = updated);
      _refreshList();
      _showMessage(
        updated.isAvailable ? 'Listing is live again' : 'Listing delisted',
      );
    } catch (e) {
      _showMessage('Could not change availability: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final room = _room;
    if (room == null || _busy) return;
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete Listing',
      message:
          'Permanently delete "${room.title}"? Its photos, likes and '
          'comments go with it. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRoomsRepositoryProvider).deleteRoom(room.id);
      if (!mounted) return;
      _refreshList();
      _showMessage('Listing deleted');
      context.go(Routes.rooms);
    } catch (e) {
      _showMessage('Could not delete: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final theme = Theme.of(context);
    return AdminPage(
      breadcrumb: 'Rooms',
      onBack: _back,
      scrollable: false,
      title: room == null
          ? 'Room details'
          : (room.title.isNotEmpty ? room.title : 'Untitled Listing'),
      subtitle: room == null
          ? null
          : [
              if (room.placeLabel.isNotEmpty) room.placeLabel,
              '₹${room.rentAmount ?? 0} / month',
            ].join(' · '),
      actions: [
        if (room != null) ...[
          ActionChip(
            avatar: Icon(
              room.isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.unpublished_rounded,
              size: 16,
              color: room.isAvailable
                  ? BrandColors.okInk
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(room.isAvailable ? 'Available' : 'Delisted'),
            tooltip: room.isAvailable
                ? 'Delist this room'
                : 'Make this room available',
            onPressed: _busy ? null : _toggleAvailable,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ],
      child: room == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : AdminErrorBanner(
                      _error ?? 'Listing not found',
                      onRetry: _load,
                    ),
            )
          : _buildBody(context, room),
    );
  }

  Widget _buildBody(BuildContext context, AdminRoomDetail room) {
    final photos = _PhotoGallery(
      urls: room.photoUrls,
      index: _photoIndex.clamp(
        0,
        room.photoUrls.isEmpty ? 0 : room.photoUrls.length - 1,
      ),
      onSelect: (i) => setState(() => _photoIndex = i),
    );
    final details = _DetailsCard(room: room);
    final description = AdminSectionCard(
      title: 'Description',
      child: SelectableText(
        room.description?.trim().isNotEmpty == true
            ? room.description!.trim()
            : 'No description provided.',
      ),
    );
    final host = _HostCard(room: room);
    // Keyed by room so a different listing never shows stale comments.
    final comments = RoomCommentsPanel(
      key: ValueKey('comments-${room.id}'),
      listingId: room.id,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              photos,
              const SizedBox(height: 16),
              details,
              const SizedBox(height: 16),
              description,
              const SizedBox(height: 16),
              host,
              const SizedBox(height: 16),
              comments,
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
                  photos,
                  const SizedBox(height: 16),
                  details,
                  const SizedBox(height: 16),
                  description,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ListView(
                children: [host, const SizedBox(height: 16), comments],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The selected photo large, with a strip of thumbnails. Tap the large photo
/// for the full-size viewer.
class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.urls,
    required this.index,
    required this.onSelect,
  });

  final List<String> urls;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (urls.isEmpty) {
      return AdminSectionCard(
        title: 'Photos (0)',
        child: Container(
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'This listing has no photos. Use Edit to upload some.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return AdminSectionCard(
      title: 'Photos (${urls.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: context.isPhone ? 220 : 340,
              child: InkWell(
                onTap: () =>
                    showImageViewer(context, urls, initialIndex: index),
                child: AdminNetworkImage(
                  // Keyed so switching photos never flashes the previous one.
                  key: ValueKey(urls[index]),
                  url: urls[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (urls.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => InkWell(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: 2,
                        color: i == index
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AdminNetworkImage(url: urls[i]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.room});

  final AdminRoomDetail room;

  @override
  Widget build(BuildContext context) {
    final lat = room.latitude;
    final lng = room.longitude;
    return AdminSectionCard(
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminInfoRow('Listing ID', room.id),
          AdminInfoRow('Listing type', humanizeEnum(room.listingType)),
          AdminInfoRow('Room type', humanizeEnum(room.roomType)),
          AdminInfoRow('Furnishing', humanizeEnum(room.furnishingStatus)),
          AdminInfoRow('Rent', '₹${room.rentAmount ?? 0} / month'),
          AdminInfoRow('Deposit', '₹${room.depositAmount ?? 0}'),
          AdminInfoRow('Gender preference', room.genderPreference.label),
          AdminInfoRow('Move-in date', room.moveInDate ?? 'Immediate'),
          AdminInfoRow(
            'Amenities',
            room.amenities.isEmpty ? '—' : room.amenities.join(', '),
          ),
          const Divider(height: 24),
          AdminInfoRow('Locality', room.localityName ?? '—'),
          AdminInfoRow('City', room.city ?? '—'),
          AdminInfoRow('State', room.stateName ?? '—'),
          AdminInfoRow('PIN code', room.postalCode ?? '—'),
          AdminInfoRow(
            'Coordinates',
            lat != null && lng != null
                ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                : '—',
          ),
          const Divider(height: 24),
          AdminInfoRow('Likes', '${room.likesCount}'),
          AdminInfoRow('Comments', '${room.commentsCount}'),
          AdminInfoRow('Created', formatAdminDate(room.createdAt)),
          AdminInfoRow('Last updated', formatAdminDate(room.updatedAt)),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.room});

  final AdminRoomDetail room;

  @override
  Widget build(BuildContext context) {
    final name = room.hostUserName?.trim().isNotEmpty == true
        ? room.hostUserName!.trim()
        : 'Unknown host';
    return AdminSectionCard(
      title: 'Host',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminAvatar(url: room.hostAvatarUrl, name: name, radius: 26),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'User ${room.hostUserId}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: room.hostUserId.isEmpty
                ? null
                : () => context.go(Routes.user(room.hostUserId)),
            icon: const Icon(Icons.person_outline),
            label: const Text('Open profile'),
          ),
        ],
      ),
    );
  }
}
