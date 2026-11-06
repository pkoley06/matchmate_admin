import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/admin_image.dart';
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
    ref.read(roomsControllerProvider.notifier).loadRooms(search: val.trim(), page: 0);
  }

  /// Creates a listing, then opens its page.
  Future<void> _showAddDialog() async {
    final created = await RoomFormDialog.show(context);
    if (created == null || !mounted) return;
    ref.read(roomsControllerProvider.notifier).loadRooms(page: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing created successfully')),
    );
    context.go(Routes.room(created.id));
  }

  void _openRoom(AdminRoomSummary room) => context.go(Routes.room(room.id));

  void _confirmDelete(AdminRoomSummary room) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to permanently delete "${room.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room / Listing Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage, moderate, and inspect flat and room listings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Add Listing'),
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
                          hintText: 'Search by title, locality, or city...',
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
                    const SizedBox(width: 8),
                    SegmentedButton<bool?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('All')),
                        ButtonSegment(value: true, label: Text('Available')),
                        ButtonSegment(value: false, label: Text('Delisted')),
                      ],
                      selected: {state.availableFilter},
                      onSelectionChanged: (val) {
                        ref
                            .read(roomsControllerProvider.notifier)
                            .loadRooms(available: val.first, page: 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref
                          .read(roomsControllerProvider.notifier)
                          .loadRooms(),
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
                                Icons.home_work_outlined,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No listings found',
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
                              final room = state.pageData!.content[index];
                              return ListTile(
                                onTap: () => _openRoom(room),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AdminNetworkImage(
                                    url: room.photoUrls.isEmpty
                                        ? null
                                        : room.photoUrls.first,
                                    width: 64,
                                    height: 48,
                                    fallbackIcon:
                                        room.listingType == 'NEED_ROOM'
                                        ? Icons.person_search_outlined
                                        : Icons.apartment_outlined,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.title.isNotEmpty
                                            ? room.title
                                            : 'Untitled Listing',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${room.rentAmount ?? 0} / mo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 14,
                                      color: theme.colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      room.placeLabel.isNotEmpty
                                          ? room.placeLabel
                                          : 'Location pending',
                                    ),
                                    const SizedBox(width: 12),
                                    if (room.roomType != null)
                                      Chip(
                                        label: Text(
                                          room.roomType!,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    const SizedBox(width: 6),
                                    Chip(
                                      avatar: Icon(
                                        room.genderPreference.isOpenToAll
                                            ? Icons.groups_outlined
                                            : Icons.person_outline,
                                        size: 12,
                                      ),
                                      label: Text(
                                        room.genderPreference.label,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 6),
                                    AdminAvatar(
                                      url: room.hostAvatarUrl,
                                      name: room.hostUserName ?? '?',
                                      radius: 9,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        room.hostUserName ?? 'Unknown host',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ActionChip(
                                      avatar: Icon(
                                        room.isAvailable
                                            ? Icons.check_circle
                                            : Icons.unpublished,
                                        size: 16,
                                        color: room.isAvailable
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      label: Text(
                                        room.isAvailable
                                            ? 'Available'
                                            : 'Delisted',
                                        style: TextStyle(
                                          color: room.isAvailable
                                              ? Colors.green.shade800
                                              : Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: () => ref
                                          .read(roomsControllerProvider.notifier)
                                          .toggleAvailability(
                                            room.id,
                                            room.isAvailable,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      tooltip:
                                          'Open room — photos, comments, edit',
                                      onPressed: () => _openRoom(room),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete listing',
                                      onPressed: () => _confirmDelete(room),
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
                            .read(roomsControllerProvider.notifier)
                            .loadRooms(page: state.pageData!.page - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: !state.pageData!.isLast
                        ? () => ref
                            .read(roomsControllerProvider.notifier)
                            .loadRooms(page: state.pageData!.page + 1)
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
