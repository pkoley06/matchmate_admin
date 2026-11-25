import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../domain/admin_room_models.dart';
import 'room_form_dialog.dart';
import 'rooms_controller.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    ref
        .read(roomsControllerProvider.notifier)
        .loadRooms(search: val.trim(), page: 0);
  }

  /// Creates a listing, then opens its page.
  Future<void> _showAddDialog() async {
    final created = await RoomFormDialog.show(context);
    if (created == null || !mounted) return;
    ref.read(roomsControllerProvider.notifier).loadRooms(page: 0);
    showAdminSnack(context, 'Listing created successfully');
    context.go(Routes.room(created.id));
  }

  void _openRoom(AdminRoomSummary room) => context.go(Routes.room(room.id));

  void _confirmDelete(AdminRoomSummary room) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to permanently delete "${room.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(roomsControllerProvider.notifier)
                  .deleteRoom(room.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomsControllerProvider);
    final controller = ref.read(roomsControllerProvider.notifier);
    final page = state.pageData;

    return AdminPage(
      title: 'Rooms',
      subtitle: 'Every room and roommate listing in the app',
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add_home_outlined, size: 18),
          label: const Text('Add Listing'),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => controller.loadRooms(),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminSearchField(
                    hint: 'Search by title, locality or city',
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
                  onPressed: () => controller.loadRooms(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AdminFilterBar<bool?>(
              filters: const [
                AdminFilter(null, 'All'),
                AdminFilter(true, 'Available'),
                AdminFilter(false, 'Delisted'),
              ],
              selected: state.availableFilter,
              onSelected: (v) => controller.loadRooms(available: v, page: 0),
            ),
            const SizedBox(height: 14),
            if (state.error != null) ...[
              AdminErrorBanner(
                state.error!,
                onRetry: () => controller.loadRooms(),
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
                icon: Icons.bed_outlined,
                title: 'No listings found',
                message: 'Try another search or filter.',
              )
            else
              for (final room in page.content) ...[
                _RoomCard(
                  room: room,
                  onOpen: () => _openRoom(room),
                  onToggle: () =>
                      controller.toggleAvailability(room.id, room.isAvailable),
                  onDelete: () => _confirmDelete(room),
                ),
                const SizedBox(height: 10),
              ],
            if (page != null)
              AdminPager(
                page: page.page,
                totalPages: page.totalPages,
                totalElements: page.totalElements,
                onPage: (p) => controller.loadRooms(page: p),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// One listing: cover, title, rent, place, host and availability.
class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  final AdminRoomSummary room;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = context.isPhone;
    return AdminCard(
      padding: const EdgeInsets.all(12),
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AdminNetworkImage(
              url: room.photoUrls.isEmpty ? null : room.photoUrls.first,
              width: phone ? 72 : 96,
              height: phone ? 60 : 72,
              fallbackIcon: room.listingType == 'NEED_ROOM'
                  ? Icons.person_search_outlined
                  : Icons.apartment_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title.isNotEmpty ? room.title : 'Untitled Listing',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '₹${room.rentAmount ?? 0} / mo · '
                  '${room.placeLabel.isNotEmpty ? room.placeLabel : 'Location pending'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    room.isAvailable
                        ? const AdminChip(
                            'Available',
                            tone: ChipTone.ok,
                            icon: Icons.check_circle_rounded,
                          )
                        : const AdminChip(
                            'Delisted',
                            icon: Icons.unpublished_rounded,
                          ),
                    if (room.roomType != null)
                      AdminChip(humanizeEnum(room.roomType)),
                    AdminChip(
                      room.genderPreference.label,
                      icon: room.genderPreference.isOpenToAll
                          ? Icons.groups_outlined
                          : Icons.person_outline,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminAvatar(
                          url: room.hostAvatarUrl,
                          name: room.hostUserName ?? '?',
                          radius: 10,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            room.hostUserName ?? 'Unknown host',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Listing actions',
            onSelected: (v) => switch (v) {
              'toggle' => onToggle(),
              'delete' => onDelete(),
              _ => onOpen(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'open',
                child: Text('Open room — photos, comments, edit'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(room.isAvailable ? 'Delist' : 'Mark available'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete listing',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
