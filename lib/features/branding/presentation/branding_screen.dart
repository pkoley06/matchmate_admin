import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _maintenance = false;
  bool _initialized = false;

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
    _maintenance = config.maintenanceMode;
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(brandingControllerProvider.notifier).updateBranding(
          AdminBrandingUpdateRequest(
            appName: _nameController.text.trim(),
            tagline: _taglineController.text.trim(),
            primaryColor: _colorController.text.trim(),
            logoUrl: _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
            splashImageUrl: _splashController.text.trim().isEmpty ? null : _splashController.text.trim(),
            supportEmail: _emailController.text.trim(),
            termsUrl: _termsController.text.trim(),
            privacyUrl: _privacyController.text.trim(),
            maintenanceMode: _maintenance,
            googleMapsApiKey: _mapsKeyController.text.trim().isEmpty
                ? null
                : _mapsKeyController.text.trim(),
            developerUpiId: _developerUpiController.text.trim().isEmpty
                ? null
                : _developerUpiController.text.trim(),
            developerQrCodeUrl: _developerQrCodeController.text.trim().isEmpty
                ? null
                : _developerQrCodeController.text.trim(),
            developerSupportNote: _developerNoteController.text.trim().isEmpty
                ? null
                : _developerNoteController.text.trim(),
          ),
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brandingControllerProvider);
    final theme = Theme.of(context);

    if (state.config != null) {
      _populate(state.config!);
    }

    return Scaffold(
      body: state.isLoading && state.config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
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
                                'Branding & App Settings',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Customize app assets, primary theme colors, and support metadata',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: state.isSaving ? null : _submit,
                          icon: state.isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Save Changes'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status Banners
                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.error!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),

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
                        TextFormField(
                          controller: _logoController,
                          decoration: const InputDecoration(
                            labelText: 'App Logo Image URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _splashController,
                          decoration: const InputDecoration(
                            labelText: 'Splash / Login Screen Banner URL',
                            border: OutlineInputBorder(),
                          ),
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
                        Row(
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
                            helperText:
                                'Displayed to mobile users in profile support card for direct UPI app payments.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _developerQrCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Developer Payment QR Code Image URL',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.qr_code_2_outlined),
                            border: OutlineInputBorder(),
                            helperText:
                                'Public image URL of your payment QR code (e.g. GPay/PhonePe/Paytm QR).',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _developerNoteController,
                          decoration: const InputDecoration(
                            labelText: 'Sweet Support Note for Users',
                            border: OutlineInputBorder(),
                            helperText:
                                'Heartwarming message thanking users for supporting independent development.',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
