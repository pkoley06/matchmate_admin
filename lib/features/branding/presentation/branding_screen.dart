import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/uploads/admin_upload_api.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/admin_detail_widgets.dart';
import '../../../core/widgets/admin_image.dart';
import '../../../core/widgets/admin_ui.dart';
import '../domain/admin_branding_models.dart';
import 'branding_controller.dart';

class BrandingScreen extends ConsumerStatefulWidget {
  const BrandingScreen({super.key});

  @override
  ConsumerState<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends ConsumerState<BrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _colorController = TextEditingController();
  final _logoController = TextEditingController();
  final _splashController = TextEditingController();
  final _emailController = TextEditingController();
  final _termsController = TextEditingController();
  final _privacyController = TextEditingController();
  final _mapsKeyController = TextEditingController();
  final _developerUpiController = TextEditingController();
  final _developerQrCodeController = TextEditingController();
  final _developerNoteController = TextEditingController();
  final _developerUpiAmountController = TextEditingController();
  final _developerUpiNoteController = TextEditingController();
  final _latestBuildController = TextEditingController(text: '7');
  final _minSupportedBuildController = TextEditingController(text: '5');
  final _releaseNotesController = TextEditingController();
  final _updateUrlController = TextEditingController(
    text: 'https://play.google.com/store/apps/details?id=com.mateeazy.app',
  );
  String _activeIcon = 'default';
  bool _maintenance = false;
  bool _communityEnabled = true;
  bool _initialized = false;

  /// The branding image being uploaded right now, if any.
  BrandingImageKind? _uploading;

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _colorController.dispose();
    _logoController.dispose();
    _splashController.dispose();
    _emailController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _mapsKeyController.dispose();
    _developerUpiController.dispose();
    _developerQrCodeController.dispose();
    _developerNoteController.dispose();
    _developerUpiAmountController.dispose();
    _developerUpiNoteController.dispose();
    _latestBuildController.dispose();
    _minSupportedBuildController.dispose();
    _releaseNotesController.dispose();
    _updateUrlController.dispose();
    super.dispose();
  }

  void _populate(AdminBrandingConfig config) {
    if (_initialized) return;
    _nameController.text = config.appName;
    _taglineController.text = config.tagline ?? '';
    _colorController.text = config.primaryColor;
    _logoController.text = config.logoUrl ?? '';
    _splashController.text = config.splashImageUrl ?? '';
    _emailController.text = config.supportEmail ?? '';
    _termsController.text = config.termsUrl ?? '';
    _privacyController.text = config.privacyUrl ?? '';
    _mapsKeyController.text = config.googleMapsApiKey ?? '';
    _developerUpiController.text = config.developerUpiId ?? '';
    _developerQrCodeController.text = config.developerQrCodeUrl ?? '';
    _developerNoteController.text = config.developerSupportNote ?? '';
    _developerUpiAmountController.text =
        config.developerUpiAmount?.toString() ?? '';
    _developerUpiNoteController.text = config.developerUpiNote ?? '';
    _latestBuildController.text = config.latestBuildNumber.toString();
    _minSupportedBuildController.text = config.minSupportedBuildNumber
        .toString();
    _releaseNotesController.text = config.releaseNotes ?? '';
    _updateUrlController.text =
        config.updateUrl ??
        'https://play.google.com/store/apps/details?id=com.mateeazy.app';
    _activeIcon = config.activeIcon ?? 'default';
    _maintenance = config.maintenanceMode;
    _communityEnabled = config.communityEnabled;
    _initialized = true;
  }

  /// Picks an image, stores it in the app's bucket and puts its URL in
  /// [target]. The URL only takes effect once the form is saved.
  Future<void> _uploadImage(
    BrandingImageKind kind,
    TextEditingController target,
  ) async {
    if (_uploading != null) return;
    final picked = await ref.read(imagePickerProvider).pick();
    if (picked.isEmpty || !mounted) return;
    setState(() => _uploading = kind);
    try {
      final url = await ref
          .read(adminUploadApiProvider)
          .uploadBrandingImage(picked.first, kind);
      if (!mounted) return;
      setState(() => target.text = url);
      showAdminSnack(
        context,
        'Image uploaded — press Save Changes to apply it',
      );
    } catch (e) {
      if (mounted) showAdminSnack(context, 'Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Every field is sent, including empty ones: the backend stores an empty
    // optional field as NULL, so clearing a value in this form really clears it.
    final success = await ref
        .read(brandingControllerProvider.notifier)
        .updateBranding(
          AdminBrandingUpdateRequest(
            appName: _nameController.text.trim(),
            tagline: _taglineController.text.trim(),
            primaryColor: _colorController.text.trim(),
            logoUrl: _logoController.text.trim(),
            splashImageUrl: _splashController.text.trim(),
            supportEmail: _emailController.text.trim(),
            termsUrl: _termsController.text.trim(),
            privacyUrl: _privacyController.text.trim(),
            maintenanceMode: _maintenance,
            communityEnabled: _communityEnabled,
            googleMapsApiKey: _mapsKeyController.text.trim(),
            developerUpiId: _developerUpiController.text.trim(),
            developerQrCodeUrl: _developerQrCodeController.text.trim(),
            developerSupportNote: _developerNoteController.text.trim(),
            // 0 tells the server to clear the amount, so the payer types
            // their own.
            developerUpiAmount:
                int.tryParse(_developerUpiAmountController.text.trim()) ?? 0,
            developerUpiNote: _developerUpiNoteController.text.trim(),
            activeIcon: _activeIcon,
            latestBuildNumber:
                int.tryParse(_latestBuildController.text.trim()) ?? 7,
            minSupportedBuildNumber:
                int.tryParse(_minSupportedBuildController.text.trim()) ?? 5,
            releaseNotes: _releaseNotesController.text.trim(),
            updateUrl: _updateUrlController.text.trim(),
          ),
        );

    if (mounted && success) {
      showAdminSnack(context, 'Settings saved successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brandingControllerProvider);
    final theme = Theme.of(context);

    if (state.config != null) {
      _populate(state.config!);
    }

    if (state.isLoading && state.config == null) {
      return const AdminPage(
        title: 'Branding',
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AdminPage(
      title: 'Branding',
      subtitle: 'App name, colours, images, support details and app versions',
      // Fixed header: Save Changes stays on screen while scrolling the form.
      scrollable: false,
      actions: [
        FilledButton.icon(
          onPressed: state.isSaving ? null : _submit,
          icon: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Banners
              if (state.error != null) ...[
                AdminErrorBanner(state.error!),
                const SizedBox(height: 16),
              ],

              // Identity Card
              _CardSection(
                title: 'App Identity',
                icon: Icons.badge_outlined,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Application Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Tagline',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _colorController,
                          decoration: const InputDecoration(
                            labelText: 'Primary Brand Color (Hex: #6750A4) *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || !v.startsWith('#'))
                              ? 'Must start with #'
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _parseColor(_colorController.text),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Asset Card
              _CardSection(
                title: 'Brand Assets',
                icon: Icons.image_outlined,
                children: [
                  _BrandingImageField(
                    label: 'App Logo',
                    helperText:
                        'Upload an image, or paste the URL of one '
                        'hosted elsewhere.',
                    controller: _logoController,
                    uploading: _uploading == BrandingImageKind.logo,
                    enabled: _uploading == null,
                    onUpload: () =>
                        _uploadImage(BrandingImageKind.logo, _logoController),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _BrandingImageField(
                    label: 'Splash / Login Screen Banner',
                    helperText: 'Shown on the splash and welcome screens.',
                    controller: _splashController,
                    uploading: _uploading == BrandingImageKind.splash,
                    enabled: _uploading == null,
                    onUpload: () => _uploadImage(
                      BrandingImageKind.splash,
                      _splashController,
                    ),
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Phone Launcher Icon Card
              _CardSection(
                title: 'Phone Launcher Icon (Dynamic Theme)',
                icon: Icons.app_shortcut_outlined,
                children: [
                  Text(
                    'Choose which app icon appears in users\' phone drawer and home screen. '
                    'Changes apply dynamically on users\' phones without needing a Play Store update.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _activeIcon,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Active App Drawer Icon',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.crop_square_rounded,
                              color: Color(0xFF6750A4),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Default (Standard MateEazy Icon)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'diwali',
                        child: Row(
                          children: [
                            Text('🪔', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Diwali Festival (Golden Diya Theme)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _activeIcon = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Support & Legal
              _CardSection(
                title: 'Support & Legal',
                icon: Icons.contact_support_outlined,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Support Contact Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldPair(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _termsController,
                          decoration: const InputDecoration(
                            labelText: 'Terms of Service URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _privacyController,
                          decoration: const InputDecoration(
                            labelText: 'Privacy Policy URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Maps & Location
              _CardSection(
                title: 'Maps & Location',
                icon: Icons.map_outlined,
                children: [
                  TextFormField(
                    controller: _mapsKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps / Places API Key',
                      hintText: 'AIzaSy...',
                      border: OutlineInputBorder(),
                      helperText:
                          'Stored securely on the server. The mobile app '
                          'fetches this key at runtime via /api/v1/branding.',
                      helperMaxLines: 2,
                    ),
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Developer Support (Buy Me a Coffee)
              _CardSection(
                title: 'Developer Support (Buy Me a Coffee)',
                icon: Icons.coffee_outlined,
                children: [
                  TextFormField(
                    controller: _developerUpiController,
                    decoration: const InputDecoration(
                      labelText: 'Developer UPI ID',
                      hintText: 'e.g. username@okaxis or phone@paytm',
                      prefixIcon: Icon(Icons.payment_outlined),
                      border: OutlineInputBorder(),
                      helperText: 'Displayed to mobile users in profile support card for direct UPI app payments.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldPair(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _developerUpiAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'UPI Amount (₹)',
                            hintText: 'Blank — the payer chooses',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                            helperText:
                                "Pre-filled in the payer's UPI app. "
                                'Leave blank so they enter any amount.',
                            helperMaxLines: 2,
                          ),
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final amount = int.tryParse(text);
                            return (amount == null || amount > 100000)
                                ? 'Up to ₹1,00,000'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _developerUpiNoteController,
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'UPI Payment Note',
                            hintText: 'e.g. Coffee for the developer',
                            border: OutlineInputBorder(),
                            helperText:
                                "The remark shown in the payer's UPI "
                                'app and on their payment record.',
                            helperMaxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _BrandingImageField(
                    label: 'Payment QR Code',
                    helperText:
                        'Your UPI QR (GPay / PhonePe / Paytm). Kept '
                        'pixel-exact so it stays scannable.',
                    controller: _developerQrCodeController,
                    uploading: _uploading == BrandingImageKind.qr,
                    enabled: _uploading == null,
                    previewFit: BoxFit.contain,
                    onUpload: () => _uploadImage(
                      BrandingImageKind.qr,
                      _developerQrCodeController,
                    ),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _developerNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Support Message shown in the App',
                      border: OutlineInputBorder(),
                      helperText: 'The message on the "Buy me a coffee" card and payment sheet.',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App Version & In-App Update Management
              _CardSection(
                title: 'App Version & In-App Updates',
                icon: Icons.system_update_rounded,
                children: [
                  _FieldPair(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latestBuildController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Latest Published Build Number *',
                            hintText: 'e.g. 7',
                            border: OutlineInputBorder(),
                            helperText: 'Active version on Google Play. Mobile apps with lower build numbers see update prompts.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _minSupportedBuildController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Supported Build Number *',
                            hintText: 'e.g. 5',
                            border: OutlineInputBorder(),
                            helperText: 'Older builds than this will be FORCE updated (non-dismissible sheet).',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _updateUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Play Store / Store Update URL',
                      hintText: 'https://play.google.com/store/apps/details?id=com.mateeazy.app',
                      border: OutlineInputBorder(),
                      helperText: 'URL launched when the user taps "Update now" in the bottom sheet.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _releaseNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Release Notes (Shown in Update Sheet)',
                      hintText: 'e.g. New flatmate search features, chat improvements, and bug fixes.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _CardSection(
                title: 'Community',
                icon: Icons.groups_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Community'),
                    subtitle: const Text(
                      'Feed, posts, statuses and follows. When off, the app hides every community section and the API rejects those requests.',
                    ),
                    value: _communityEnabled,
                    onChanged: (val) => setState(() => _communityEnabled = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // System Status
              _CardSection(
                title: 'Maintenance Mode',
                icon: Icons.build_circle_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Maintenance Mode'),
                    subtitle: const Text(
                      'Temporarily prevent mobile users from discovering rooms or updating profiles',
                    ),
                    value: _maintenance,
                    onChanged: (val) => setState(() => _maintenance = val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      }
    } catch (_) {}
    return const Color(0xFF6750A4);
  }
}

/// One branding image: a preview, an upload button and the URL itself (still
/// editable, for an image hosted somewhere else).
class _BrandingImageField extends StatelessWidget {
  const _BrandingImageField({
    required this.label,
    required this.helperText,
    required this.controller,
    required this.uploading,
    required this.enabled,
    required this.onUpload,
    required this.onChanged,
    this.previewFit = BoxFit.cover,
  });

  final String label;
  final String helperText;
  final TextEditingController controller;
  final bool uploading;
  final bool enabled;
  final VoidCallback onUpload;

  /// The URL changed (typed, uploaded or cleared) — refresh the preview.
  final VoidCallback onChanged;
  final BoxFit previewFit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = controller.text.trim();
    final hasImage = isImageUrl(url);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 420;
        return Flex(
          direction: narrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: hasImage ? () => showImageViewer(context, [url]) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: narrow ? 96 : 120,
                height: narrow ? 96 : 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: AdminNetworkImage(
                  key: ValueKey(url),
                  url: hasImage ? url : null,
                  fit: previewFit,
                  fallbackIcon: Icons.image_outlined,
                ),
              ),
            ),
            const SizedBox(width: 16, height: 12),
            Flexible(
              // flex 0 when stacked: a vertical Flex here has no height to share.
              flex: narrow ? 0 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: '$label — image URL',
                      hintText: 'https://...',
                      border: const OutlineInputBorder(),
                      helperText: helperText,
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: enabled ? onUpload : null,
                        icon: uploading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_outlined),
                        label: Text(
                          uploading
                              ? 'Uploading…'
                              : (hasImage ? 'Replace image' : 'Upload image'),
                        ),
                      ),
                      if (url.isNotEmpty)
                        TextButton.icon(
                          onPressed: enabled
                              ? () {
                                  controller.clear();
                                  onChanged();
                                }
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Two form fields side by side; stacked on a phone.
class _FieldPair extends StatelessWidget {
  const _FieldPair({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (!context.isPhone) {
      return Row(crossAxisAlignment: crossAxisAlignment, children: children);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in children)
          if (c is Expanded)
            c.child
          else if (c is SizedBox && c.width != null && c.height == null)
            const SizedBox(height: 16)
          else
            c,
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: BrandColors.coralInk),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
