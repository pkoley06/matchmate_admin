import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/admin_places_service.dart';
import '../../../core/uploads/admin_upload_api.dart';
import '../../../core/widgets/admin_image.dart';
import '../../users/data/admin_users_repository.dart';
import '../../users/domain/admin_user_models.dart';
import '../data/admin_rooms_repository.dart';
import '../domain/admin_room_models.dart';

/// Create a listing, or — with [initial] — edit every detail of an existing
/// one, photos included. Pops with the saved [AdminRoomDetail].
class RoomFormDialog extends ConsumerStatefulWidget {
  const RoomFormDialog({
    super.key,
    this.initial,
    this.initialHostUserId,
    this.initialHostName,
    this.initialHostAvatarUrl,
  });

  /// The listing being edited; null creates a new one.
  final AdminRoomDetail? initial;

  /// Creating from a user's page: the listing is for that user, so the host
  /// is fixed instead of chosen from a list.
  final String? initialHostUserId;
  final String? initialHostName;
  final String? initialHostAvatarUrl;

  static Future<AdminRoomDetail?> show(
    BuildContext context, {
    AdminRoomDetail? initial,
    String? initialHostUserId,
    String? initialHostName,
    String? initialHostAvatarUrl,
  }) => showDialog<AdminRoomDetail>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RoomFormDialog(
      initial: initial,
      initialHostUserId: initialHostUserId,
      initialHostName: initialHostName,
      initialHostAvatarUrl: initialHostAvatarUrl,
    ),
  );

  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> {
  static const _maxPhotos = 10;
  static const _coral = Color(0xFFFF6B5B);

  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.initial != null;

  /// The host cannot be picked: an existing listing keeps its host, and a
  /// listing added from a user's page belongs to that user.
  bool get _hostFixed => _isEdit || widget.initialHostUserId != null;

  // Host (only chosen when creating; a listing keeps its host).
  List<AdminUserSummary> _users = [];
  bool _loadingUsers = false;
  String? _selectedHostUserId;

  late final TextEditingController _titleController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  // Location fields are filled from the chosen place, never from a hardcoded
  // city.
  late final TextEditingController _localityController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _descController;
  late final TextEditingController _moveInController;
  late final TextEditingController _amenitiesController;

  final _placeSearchController = TextEditingController();
  List<AdminPlacePrediction> _predictions = [];
  bool _isSearchingPlace = false;

  late String _listingType;
  late String _roomType;
  late String _furnishing;
  late AdminGenderPreference _genderPreference;
  late bool _isAvailable;
  late List<String> _photoUrls;

  bool _uploading = false;
  bool _saving = false;
  String? _error;

  double? get _latitude => double.tryParse(_latController.text.trim());
  double? get _longitude => double.tryParse(_lngController.text.trim());

  @override
  void initState() {
    super.initState();
    final room = widget.initial;
    _titleController = TextEditingController(text: room?.title ?? '');
    _rentController = TextEditingController(
      text: '${room?.rentAmount ?? 12000}',
    );
    _depositController = TextEditingController(
      text: '${room?.depositAmount ?? 24000}',
    );
    _localityController = TextEditingController(text: room?.localityName ?? '');
    _cityController = TextEditingController(text: room?.city ?? '');
    _stateController = TextEditingController(text: room?.stateName ?? '');
    _postalCodeController = TextEditingController(text: room?.postalCode ?? '');
    _latController = TextEditingController(
      text: room?.latitude?.toStringAsFixed(6) ?? '',
    );
    _lngController = TextEditingController(
      text: room?.longitude?.toStringAsFixed(6) ?? '',
    );
    _descController = TextEditingController(text: room?.description ?? '');
    _moveInController = TextEditingController(text: room?.moveInDate ?? '');
    _amenitiesController = TextEditingController(
      text: room?.amenities.join(', ') ?? '',
    );
    _listingType = room?.listingType ?? 'HAVE_ROOM';
    _roomType = room?.roomType ?? 'PRIVATE_ROOM';
    _furnishing = room?.furnishingStatus ?? 'FULLY_FURNISHED';
    _genderPreference = room?.genderPreference ?? AdminGenderPreference.all;
    _isAvailable = room?.isAvailable ?? true;
    _photoUrls = [...?room?.photoUrls];
    _selectedHostUserId = room?.hostUserId ?? widget.initialHostUserId;
    if (!_hostFixed) _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final page = await ref
          .read(adminUsersRepositoryProvider)
          .listUsers(size: 100);
      if (!mounted) return;
      setState(() {
        _users = page.content;
        _loadingUsers = false;
        _selectedHostUserId = _users.isNotEmpty ? _users.first.id : null;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _rentController,
      _depositController,
      _localityController,
      _cityController,
      _stateController,
      _postalCodeController,
      _latController,
      _lngController,
      _descController,
      _moveInController,
      _amenitiesController,
      _placeSearchController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onSearchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _isSearchingPlace = true);
    final results = await ref
        .read(adminPlacesServiceProvider)
        .autocomplete(query);
    if (mounted) {
      setState(() {
        _predictions = results;
        _isSearchingPlace = false;
      });
    }
  }

  Future<void> _selectPlace(AdminPlacePrediction p) async {
    final details = await ref
        .read(adminPlacesServiceProvider)
        .fetchPlaceDetails(p.placeId);
    if (details == null || !mounted) return;
    setState(() {
      _predictions = [];
      _placeSearchController.text = p.primaryText;
      _latController.text = details.latitude.toStringAsFixed(6);
      _lngController.text = details.longitude.toStringAsFixed(6);
      _localityController.text = details.locality?.isNotEmpty == true
          ? details.locality!
          : p.primaryText;
      if (details.city?.isNotEmpty == true) {
        _cityController.text = details.city!;
      }
      if (details.stateName?.isNotEmpty == true) {
        _stateController.text = details.stateName!;
      }
      if (details.postalCode?.isNotEmpty == true) {
        _postalCodeController.text = details.postalCode!;
      }
    });
  }

  Future<void> _pickMoveInDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_moveInController.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    _moveInController.text =
        '${picked.year}-${two(picked.month)}-${two(picked.day)}';
  }

  /// Picks images and uploads them straight away; the URLs join the listing
  /// when the form is saved.
  Future<void> _addPhotos() async {
    final room = _maxPhotos - _photoUrls.length;
    if (room <= 0) return;
    final picked = await ref.read(imagePickerProvider).pick(multiple: true);
    if (picked.isEmpty || !mounted) return;
    final batch = picked.take(room).toList();
    setState(() {
      _uploading = true;
      _error = picked.length > room
          ? 'A listing holds at most $_maxPhotos photos — only the first '
                '$room were added.'
          : null;
    });
    try {
      final urls = await ref
          .read(adminUploadApiProvider)
          .uploadListingPhotos(batch, hostUserId: _selectedHostUserId);
      if (mounted) setState(() => _photoUrls = [..._photoUrls, ...urls]);
    } catch (e) {
      if (mounted) setState(() => _error = 'Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(String url) =>
      setState(() => _photoUrls = _photoUrls.where((u) => u != url).toList());

  /// The first photo is the cover the app shows on cards.
  void _makeCover(String url) => setState(
    () => _photoUrls = [url, ..._photoUrls.where((u) => u != url)],
  );

  List<String> get _amenities => _amenitiesController.text
      .split(',')
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final latitude = _latitude;
    final longitude = _longitude;
    if (_selectedHostUserId == null) {
      setState(() => _error = 'Please select a host user.');
      return;
    }
    if (latitude == null || longitude == null) {
      setState(
        () => _error = 'Pick a place so the listing has coordinates.',
      );
      return;
    }
    final moveIn = _moveInController.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(adminRoomsRepositoryProvider);
    try {
      final AdminRoomDetail saved;
      if (_isEdit) {
        saved = await repo.updateRoom(
          widget.initial!.id,
          AdminRoomUpdateRequest(
            listingType: _listingType,
            title: _titleController.text.trim(),
            rentAmount: int.tryParse(_rentController.text.trim()) ?? 0,
            depositAmount: int.tryParse(_depositController.text.trim()) ?? 0,
            roomType: _roomType,
            furnishingStatus: _furnishing,
            latitude: latitude,
            longitude: longitude,
            localityName: _localityController.text.trim(),
            city: _cityController.text.trim(),
            // Sent even when empty: an empty value clears the field.
            stateName: _stateController.text.trim(),
            postalCode: _postalCodeController.text.trim(),
            description: _descController.text.trim(),
            photoUrls: _photoUrls,
            moveInDate: moveIn.isEmpty ? null : moveIn,
            amenities: _amenities,
            genderPreference: _genderPreference,
            isAvailable: _isAvailable,
          ),
        );
      } else {
        saved = await repo.createRoom(
          AdminRoomCreateRequest(
            hostUserId: _selectedHostUserId!,
            listingType: _listingType,
            title: _titleController.text.trim(),
            rentAmount: int.tryParse(_rentController.text.trim()) ?? 0,
            depositAmount: int.tryParse(_depositController.text.trim()) ?? 0,
            roomType: _roomType,
            furnishingStatus: _furnishing,
            latitude: latitude,
            longitude: longitude,
            localityName: _localityController.text.trim(),
            city: _cityController.text.trim(),
            stateName: _stateController.text.trim(),
            postalCode: _postalCodeController.text.trim(),
            description: _descController.text.trim(),
            photoUrls: _photoUrls,
            moveInDate: moveIn.isEmpty ? null : moveIn,
            amenities: _amenities,
            genderPreference: _genderPreference,
            isAvailable: _isAvailable,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? _amount(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 0) ? 'Enter a whole number' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _saving || _uploading;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEdit ? Icons.edit_outlined : Icons.add_home_work_outlined,
            color: _coral,
          ),
          const SizedBox(width: 8),
          Text(_isEdit ? 'Edit Room Listing' : 'Add Room Listing'),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _buildHost(theme),
                const SizedBox(height: 16),

                _sectionTitle(theme, 'Photos'),
                const SizedBox(height: 8),
                _buildPhotos(theme),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Listing Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _listingType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Listing Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'HAVE_ROOM',
                            child: Text('Have Room'),
                          ),
                          DropdownMenuItem(
                            value: 'NEED_ROOM',
                            child: Text('Need Room'),
                          ),
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Room Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PRIVATE_ROOM',
                            child: Text('Private Room'),
                          ),
                          DropdownMenuItem(
                            value: 'SHARED_ROOM',
                            child: Text('Shared Room'),
                          ),
                          DropdownMenuItem(
                            value: 'ENTIRE_FLAT',
                            child: Text('Entire Flat'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _roomType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
                        validator: _amount,
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
                        validator: _amount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _furnishing,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Furnishing Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'FULLY_FURNISHED',
                            child: Text('Fully Furnished'),
                          ),
                          DropdownMenuItem(
                            value: 'SEMI_FURNISHED',
                            child: Text('Semi Furnished'),
                          ),
                          DropdownMenuItem(
                            value: 'UNFURNISHED',
                            child: Text('Unfurnished'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _furnishing = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<AdminGenderPreference>(
                        initialValue: _genderPreference,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Gender Preference',
                          border: OutlineInputBorder(),
                        ),
                        items: AdminGenderPreference.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _genderPreference = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _moveInController,
                        readOnly: true,
                        onTap: _pickMoveInDate,
                        decoration: const InputDecoration(
                          labelText: 'Move-in Date',
                          hintText: 'Immediate',
                          prefixIcon: Icon(Icons.event_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available'),
                        subtitle: Text(
                          _isAvailable ? 'Shown in the app' : 'Delisted',
                        ),
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities',
                    hintText: 'WiFi, AC, Washing machine',
                    helperText: 'Separate with commas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                _sectionTitle(theme, 'Location'),
                const SizedBox(height: 8),
                ..._buildLocation(theme),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 2000,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save Changes' : 'Create Listing'),
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Text(
    text,
    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _buildHost(ThemeData theme) {
    if (_hostFixed) {
      final room = widget.initial;
      final name =
          room?.hostUserName ?? widget.initialHostName ?? 'Unknown host';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: AdminAvatar(
          url: room?.hostAvatarUrl ?? widget.initialHostAvatarUrl,
          name: name,
        ),
        title: Text(name),
        subtitle: Text(
          _isEdit
              ? 'Host — a listing keeps the user it belongs to'
              : 'Host — this listing will belong to this user',
        ),
      );
    }
    if (_loadingUsers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedHostUserId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assign to User (Host) *',
        prefixIcon: Icon(Icons.person_search_outlined),
        border: OutlineInputBorder(),
      ),
      items: _users
          .map(
            (u) => DropdownMenuItem<String>(
              value: u.id,
              child: Text(
                '${u.fullName} • ${u.lastKnownLocality ?? u.gender ?? 'Active'}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedHostUserId = val);
      },
      validator: (v) => v == null ? 'Please select a host user' : null,
    );
  }

  Widget _buildPhotos(ThemeData theme) {
    final canAdd = _photoUrls.length < _maxPhotos && !_uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (index, url) in _photoUrls.indexed)
              _PhotoTile(
                url: url,
                isCover: index == 0,
                onView: () =>
                    showImageViewer(context, _photoUrls, initialIndex: index),
                onRemove: () => _removePhoto(url),
                onMakeCover: index == 0 ? null : () => _makeCover(url),
              ),
            InkWell(
              onTap: canAdd ? _addPhotos : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_uploading)
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: canAdd
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _uploading ? 'Uploading…' : 'Add photos',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_photoUrls.length} / $_maxPhotos • the first photo is the cover',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLocation(ThemeData theme) {
    final lat = _latitude;
    final lng = _longitude;
    return [
      TextFormField(
        controller: _placeSearchController,
        onChanged: _onSearchPlace,
        decoration: InputDecoration(
          labelText: 'Search Google Places / Address...',
          hintText: 'e.g. Koramangala, Indiranagar, Salt Lake',
          prefixIcon: const Icon(Icons.search, color: _coral),
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
      if (_predictions.isNotEmpty) ...[
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
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
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: _coral,
                ),
                title: Text(
                  p.primaryText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: p.secondaryText.isNotEmpty
                    ? Text(
                        p.secondaryText,
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
                onTap: () => _selectPlace(p),
              );
            },
          ),
        ),
      ],
      const SizedBox(height: 8),
      Text(
        lat != null && lng != null
            ? 'Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
            : 'Search a place above to set the coordinates',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _localityController,
              decoration: const InputDecoration(
                labelText: 'Locality *',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City *',
                hintText: 'Filled from the selected place',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'PIN Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
    ];
  }
}

/// One photo in the editor: tap to view, with "cover" and "remove" controls.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.isCover,
    required this.onView,
    required this.onRemove,
    required this.onMakeCover,
  });

  final String url;
  final bool isCover;
  final VoidCallback onView;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onView,
                child: AdminNetworkImage(url: url),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Cover',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMakeCover != null)
                  _TileButton(
                    icon: Icons.star_outline,
                    tooltip: 'Make cover photo',
                    onPressed: onMakeCover!,
                  ),
                _TileButton(
                  icon: Icons.close,
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
