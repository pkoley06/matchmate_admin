import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/admin_places_service.dart';
import '../../users/data/admin_users_repository.dart';
import '../../users/domain/admin_user_models.dart';
import '../domain/admin_room_models.dart';
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

  void _showAddDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _RoomFormDialog(),
    );
  }

  void _showDetailDialog(AdminRoomSummary room) async {
    final detail = await ref
        .read(roomsControllerProvider.notifier)
        .fetchDetail(room.id);
    if (!mounted || detail == null) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => _RoomDetailDialog(detail: detail),
    );
  }

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
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    room.listingType == 'NEED_ROOM'
                                        ? Icons.person_search_outlined
                                        : Icons.apartment_outlined,
                                    color: theme.colorScheme.primary,
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
                                      '${room.localityName ?? ""}, ${room.city ?? ""}',
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
                                    Text(
                                      'Host: ${room.hostUserName ?? "ID ${room.hostUserId}"}',
                                      style: theme.textTheme.bodySmall,
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
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'Inspect details',
                                      onPressed: () => _showDetailDialog(room),
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

class _RoomDetailDialog extends StatelessWidget {
  const _RoomDetailDialog({required this.detail});

  final AdminRoomDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.apartment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.title),
                Text(
                  'Listing #${detail.id} • Host: ${detail.hostUserName ?? "ID ${detail.hostUserId}"}',
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
              _infoTile('Listing Type', detail.listingType ?? 'HAVE_ROOM'),
              _infoTile('Room Type', detail.roomType ?? 'N/A'),
              _infoTile('Furnishing', detail.furnishingStatus ?? 'N/A'),
              _infoTile('Rent Amount', '₹${detail.rentAmount ?? 0} / month'),
              _infoTile('Security Deposit', '₹${detail.depositAmount ?? 0}'),
              _infoTile('Locality', detail.localityName ?? 'N/A'),
              _infoTile('City', detail.city ?? 'N/A'),
              _infoTile('Coordinates', '${detail.latitude ?? "N/A"}, ${detail.longitude ?? "N/A"}'),
              _infoTile('Move-in Date', detail.moveInDate ?? 'Immediate'),
              _infoTile('Open to All Genders', detail.openToAllGenders ? 'Yes' : 'No'),
              _infoTile('Available', detail.isAvailable ? 'Yes' : 'No'),
              if (detail.amenities.isNotEmpty)
                _infoTile('Amenities', detail.amenities.join(', ')),
              const Divider(height: 24),
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(detail.description ?? 'No description provided'),
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

class _RoomFormDialog extends ConsumerStatefulWidget {
  const _RoomFormDialog();

  @override
  ConsumerState<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Users
  List<AdminUserSummary> _users = [];
  bool _loadingUsers = true;
  int? _selectedHostUserId;

  // Form Fields
  final _titleController = TextEditingController();
  final _rentController = TextEditingController(text: '12000');
  final _depositController = TextEditingController(text: '24000');
  final _localityController = TextEditingController();
  final _cityController = TextEditingController(text: 'Kolkata');
  final _latController = TextEditingController(text: '22.5726');
  final _lngController = TextEditingController(text: '88.3639');
  final _descController = TextEditingController();

  // Places Autocomplete
  final _placeSearchController = TextEditingController();
  List<AdminPlacePrediction> _predictions = [];
  bool _isSearchingPlace = false;

  String _listingType = 'HAVE_ROOM';
  String _roomType = 'PRIVATE_ROOM';
  String _furnishing = 'FULLY_FURNISHED';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final page = await ref.read(adminUsersRepositoryProvider).listUsers(size: 100);
      if (mounted) {
        setState(() {
          _users = page.content;
          _loadingUsers = false;
          if (_users.isNotEmpty) {
            _selectedHostUserId = _users.first.id;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descController.dispose();
    _placeSearchController.dispose();
    super.dispose();
  }

  void _onSearchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _isSearchingPlace = true);
    final results = await ref.read(adminPlacesServiceProvider).autocomplete(query);
    if (mounted) {
      setState(() {
        _predictions = results;
        _isSearchingPlace = false;
      });
    }
  }

  void _selectPlace(AdminPlacePrediction p) async {
    final details = await ref.read(adminPlacesServiceProvider).fetchPlaceDetails(p.placeId);
    if (details != null && mounted) {
      setState(() {
        _predictions = [];
        _placeSearchController.text = p.primaryText;
        _latController.text = details.latitude.toStringAsFixed(6);
        _lngController.text = details.longitude.toStringAsFixed(6);
        if (details.locality != null && details.locality!.isNotEmpty) {
          _localityController.text = details.locality!;
        } else {
          _localityController.text = p.primaryText;
        }
        if (details.city != null && details.city!.isNotEmpty) {
          _cityController.text = details.city!;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedHostUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a host user')),
      );
      return;
    }

    setState(() => _saving = true);
    final success = await ref.read(roomsControllerProvider.notifier).createRoom(
          AdminRoomCreateRequest(
            hostUserId: _selectedHostUserId!,
            listingType: _listingType,
            title: _titleController.text.trim(),
            rentAmount: int.tryParse(_rentController.text.trim()) ?? 0,
            depositAmount: int.tryParse(_depositController.text.trim()) ?? 0,
            roomType: _roomType,
            furnishingStatus: _furnishing,
            latitude: double.tryParse(_latController.text.trim()) ?? 22.5726,
            longitude: double.tryParse(_lngController.text.trim()) ?? 88.3639,
            localityName: _localityController.text.trim(),
            city: _cityController.text.trim(),
            description: _descController.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLat = double.tryParse(_latController.text.trim()) ?? 22.5726;
    final currentLng = double.tryParse(_lngController.text.trim()) ?? 88.3639;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_home_work_outlined, color: Color(0xFFFF6B5B)),
          SizedBox(width: 8),
          Text('Add Room Listing'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Assign to Any User (Host Selector)
                if (_loadingUsers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedHostUserId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to User (Host) *',
                      prefixIcon: Icon(Icons.person_search_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _users.map((u) {
                      return DropdownMenuItem<int>(
                        value: u.id,
                        child: Text(
                          '${u.fullName} (ID: ${u.id}) • ${u.lastKnownLocality ?? u.gender ?? 'Active'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedHostUserId = val);
                    },
                    validator: (v) => v == null ? 'Please select a host user' : null,
                  ),
                const SizedBox(height: 16),

                // 2. Listing Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Listing Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // 3. Listing Type & Room Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _listingType,
                        decoration: const InputDecoration(
                          labelText: 'Listing Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'HAVE_ROOM', child: Text('Have Room')),
                          DropdownMenuItem(value: 'NEED_ROOM', child: Text('Need Room')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _listingType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _roomType,
                        decoration: const InputDecoration(
                          labelText: 'Room Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PRIVATE_ROOM', child: Text('Private Room')),
                          DropdownMenuItem(value: 'SHARED_ROOM', child: Text('Shared Room')),
                          DropdownMenuItem(value: 'ENTIRE_FLAT', child: Text('Entire Flat')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _roomType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Rent & Deposit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rentController,
                        decoration: const InputDecoration(
                          labelText: 'Rent (₹/mo) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        decoration: const InputDecoration(
                          labelText: 'Deposit (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Furnishing Status
                DropdownButtonFormField<String>(
                  initialValue: _furnishing,
                  decoration: const InputDecoration(
                    labelText: 'Furnishing Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FULLY_FURNISHED', child: Text('Fully Furnished')),
                    DropdownMenuItem(value: 'SEMI_FURNISHED', child: Text('Semi Furnished')),
                    DropdownMenuItem(value: 'UNFURNISHED', child: Text('Unfurnished')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _furnishing = val);
                  },
                ),
                const SizedBox(height: 16),

                // 6. Google Place Autocomplete Search Input
                Text(
                  'Location & Map Placement',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placeSearchController,
                  onChanged: _onSearchPlace,
                  decoration: InputDecoration(
                    labelText: 'Search Google Places / Address...',
                    hintText: 'e.g. Koramangala, Indiranagar, Salt Lake',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B5B)),
                    suffixIcon: _isSearchingPlace
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_placeSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _placeSearchController.clear();
                                  setState(() => _predictions = []);
                                },
                              )
                            : null),
                    border: const OutlineInputBorder(),
                  ),
                ),

                // Inline suggestions below search bar
                if (_predictions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _predictions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final p = _predictions[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFFF6B5B)),
                          title: Text(p.primaryText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: p.secondaryText.isNotEmpty
                              ? Text(p.secondaryText, style: const TextStyle(fontSize: 11))
                              : null,
                          onTap: () => _selectPlace(p),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // 7. Interactive Map Preview with Glowing Center Pin
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Map Background Canvas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AdminGridMapPainter(),
                        ),
                      ),

                      // Glowing Center Pin
                      Center(
                        child: Transform.translate(
                          offset: const Offset(0, -14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF7E6B), Color(0xFFFF6B5B), Color(0xFFE04231)],
                                  ),
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B5B).withValues(alpha: 0.65),
                                      blurRadius: 18,
                                      spreadRadius: 6,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 14,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: const BorderRadius.all(Radius.elliptical(14, 5)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B5B).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live Coordinates Pill
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Selected Coordinates: ${currentLat.toStringAsFixed(4)}, ${currentLng.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 8. Locality, City & Coordinates Fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _localityController,
                        decoration: const InputDecoration(
                          labelText: 'Locality *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 9. Description
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
              : const Text('Create Listing'),
        ),
      ],
    );
  }
}

class _AdminGridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x15000000)
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
