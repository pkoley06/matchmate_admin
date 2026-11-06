import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/uploads/admin_upload_api.dart';
import '../../../core/widgets/admin_image.dart';
import '../data/admin_users_repository.dart';
import '../domain/admin_user_models.dart';

/// Create a user, or — with [initial] — edit any user's profile, photo
/// included. Pops with the saved [AdminUserDetail].
class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key, this.initial});

  /// The user being edited; null creates a new one.
  final AdminUserDetail? initial;

  static Future<AdminUserDetail?> show(
    BuildContext context, {
    AdminUserDetail? initial,
  }) => showDialog<AdminUserDetail>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UserFormDialog(initial: initial),
  );

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  // Values mirror the backend enums.
  static const _genders = {
    'MALE': 'Male',
    'FEMALE': 'Female',
    'NON_BINARY': 'Non-binary',
    'OTHERS': 'Other',
  };
  static const _occupations = {
    'STUDENT': 'Student',
    'WORKING_PROFESSIONAL': 'Working professional',
  };
  static const _smoking = {
    'NON_SMOKER': 'Non-smoker',
    'OCCASIONAL_SMOKER': 'Occasional / balcony',
    'REGULAR_SMOKER': 'Regular smoker',
  };
  static const _diets = {
    'VEGETARIAN': 'Vegetarian',
    'NON_VEGETARIAN': 'Non-vegetarian',
    'VEGAN': 'Vegan',
    'EGGETARIAN': 'Eggetarian',
    'NO_PREFERENCE': 'No preference',
  };
  static const _sleep = {
    'EARLY_BIRD': 'Early bird',
    'FLEXIBLE': 'Flexible',
    'NIGHT_OWL': 'Night owl',
  };
  static const _cleanliness = {
    'VERY_CLEAN': 'Very clean',
    'MODERATE': 'Moderate',
    'RELAXED': 'Relaxed',
  };
  static const _guests = {
    'NEVER': 'No guests',
    'OCCASIONAL': 'Occasional guests',
    'FREQUENT': 'Frequent guests',
  };

  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.initial != null;

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _localityController;
  late final TextEditingController _occupationController;
  late final TextEditingController _bioController;

  String? _gender;
  String? _occupationCategory;
  String? _smokingHabit;
  String? _diet;
  String? _sleepSchedule;
  String? _cleanlinessLevel;
  String? _guestTolerance;

  /// Null or empty means "no photo".
  String? _avatarUrl;

  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.initial;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    _localityController = TextEditingController(
      text: user?.lastKnownLocality ?? '',
    );
    _occupationController = TextEditingController(
      text: user?.occupationTitle ?? '',
    );
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarUrl = user?.avatarUrl;
    if (user != null) {
      _gender = _known(_genders, user.gender);
      _occupationCategory = _known(_occupations, user.occupationCategory);
      _smokingHabit = _known(_smoking, user.smokingHabit);
      _diet = _known(_diets, user.dietaryPreference);
      _sleepSchedule = _known(_sleep, user.sleepSchedule);
      _cleanlinessLevel = _known(_cleanliness, user.cleanlinessLevel);
      _guestTolerance = _known(_guests, user.guestTolerance);
    } else {
      _gender = 'MALE';
    }
  }

  /// A dropdown can only show a value it has an item for.
  static String? _known(Map<String, String> options, String? value) =>
      options.containsKey(value) ? value : null;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _localityController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final adult = DateTime(now.year - 18, now.month, now.day);
    final current = DateTime.tryParse(_dobController.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isAfter(adult)
          ? current
          : DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      // Accounts are for adults only; the server enforces it too.
      lastDate: adult,
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    _dobController.text =
        '${picked.year}-${two(picked.month)}-${two(picked.day)}';
  }

  Future<void> _pickPhoto() async {
    final picked = await ref.read(imagePickerProvider).pick();
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(adminUploadApiProvider)
          .uploadProfilePhoto(picked.first, userId: widget.initial?.id);
      if (mounted) setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) setState(() => _error = 'Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(adminUsersRepositoryProvider);
    final avatar = _avatarUrl?.trim() ?? '';
    try {
      final AdminUserDetail saved;
      final user = widget.initial;
      if (user != null) {
        saved = await repo.updateUser(
          user.id,
          AdminUserUpdateRequest(
            fullName: _nameController.text.trim(),
            gender: _gender,
            dateOfBirth: _dobController.text.trim().isEmpty
                ? null
                : _dobController.text.trim(),
            // Only sent when it changed; an empty value removes the photo.
            avatarUrl: avatar == (user.avatarUrl?.trim() ?? '') ? null : avatar,
            occupationCategory: _occupationCategory,
            occupationTitle: _occupationController.text.trim(),
            bio: _bioController.text.trim(),
            lastKnownLocality: _localityController.text.trim(),
            smokingHabit: _smokingHabit,
            dietaryPreference: _diet,
            sleepSchedule: _sleepSchedule,
            cleanlinessLevel: _cleanlinessLevel,
            guestTolerance: _guestTolerance,
          ),
        );
      } else {
        saved = await repo.createUser(
          AdminUserCreateRequest(
            fullName: _nameController.text.trim(),
            gender: _gender ?? 'MALE',
            dateOfBirth: _dobController.text.trim(),
            avatarUrl: avatar.isEmpty ? null : avatar,
            occupationCategory: _occupationCategory,
            occupationTitle: _occupationController.text.trim(),
            bio: _bioController.text.trim(),
            lastKnownLocality: _localityController.text.trim(),
            smokingHabit: _smokingHabit,
            dietaryPreference: _diet,
            sleepSchedule: _sleepSchedule,
            cleanlinessLevel: _cleanlinessLevel,
            guestTolerance: _guestTolerance,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _saving || _uploading;
    final hasPhoto = isImageUrl(_avatarUrl);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'Add User'),
      content: SizedBox(
        width: 560,
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

                // Profile photo
                Row(
                  children: [
                    AdminAvatar(
                      url: _avatarUrl,
                      name: _nameController.text,
                      radius: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: busy ? null : _pickPhoto,
                            icon: _uploading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_outlined),
                            label: Text(
                              _uploading
                                  ? 'Uploading…'
                                  : (hasPhoto
                                        ? 'Change photo'
                                        : 'Upload photo'),
                            ),
                          ),
                          if (hasPhoto)
                            TextButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _avatarUrl = ''),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: _required,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Gender',
                        options: _genders,
                        value: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                        allowUnset: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDob,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth *',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(),
                        ),
                        // An existing account may predate the field.
                        validator: _isEdit ? null : _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _localityController,
                  decoration: const InputDecoration(
                    labelText: 'Locality / Area',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Occupation',
                        options: _occupations,
                        value: _occupationCategory,
                        onChanged: (v) =>
                            setState(() => _occupationCategory = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _occupationController,
                        decoration: const InputDecoration(
                          labelText: 'Occupation Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lifestyle answers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Smoking Habit',
                        options: _smoking,
                        value: _smokingHabit,
                        onChanged: (v) => setState(() => _smokingHabit = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                        label: 'Dietary Preference',
                        options: _diets,
                        value: _diet,
                        onChanged: (v) => setState(() => _diet = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Sleep Schedule',
                        options: _sleep,
                        value: _sleepSchedule,
                        onChanged: (v) => setState(() => _sleepSchedule = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                        label: 'Cleanliness',
                        options: _cleanliness,
                        value: _cleanlinessLevel,
                        onChanged: (v) =>
                            setState(() => _cleanlinessLevel = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dropdown(
                  label: 'Guest Tolerance',
                  options: _guests,
                  value: _guestTolerance,
                  onChanged: (v) => setState(() => _guestTolerance = v),
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
              : Text(_isEdit ? 'Save Changes' : 'Create User'),
        ),
      ],
    );
  }

  /// [allowUnset] adds a "Not answered" entry, which leaves the field as it is
  /// on the server.
  Widget _dropdown({
    required String label,
    required Map<String, String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool allowUnset = true,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (allowUnset || value == null)
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Not answered'),
          ),
        for (final entry in options.entries)
          DropdownMenuItem<String?>(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
