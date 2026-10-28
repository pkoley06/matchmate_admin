class AdminBrandingConfig {
  const AdminBrandingConfig({
    required this.id,
    required this.appName,
    this.tagline,
    required this.primaryColor,
    this.logoUrl,
    this.splashImageUrl,
    this.supportEmail,
    this.termsUrl,
    this.privacyUrl,
    required this.maintenanceMode,
    this.googleMapsApiKey,
    this.developerUpiId,
    this.developerQrCodeUrl,
    this.developerSupportNote,
    this.updatedAt,
  });

  final int id;
  final String appName;
  final String? tagline;
  final String primaryColor;
  final String? logoUrl;
  final String? splashImageUrl;
  final String? supportEmail;
  final String? termsUrl;
  final String? privacyUrl;
  final bool maintenanceMode;
  /// Google Maps / Places API key; stored server-side and served to the
  /// mobile app via the public /api/v1/branding endpoint.
  final String? googleMapsApiKey;
  final String? developerUpiId;
  final String? developerQrCodeUrl;
  final String? developerSupportNote;
  final DateTime? updatedAt;

  factory AdminBrandingConfig.fromJson(Map<String, dynamic> json) =>
      AdminBrandingConfig(
        id: (json['id'] as num).toInt(),
        appName: (json['appName'] as String?) ?? 'MatchMate',
        tagline: json['tagline'] as String?,
        primaryColor: (json['primaryColor'] as String?) ?? '#6750A4',
        logoUrl: json['logoUrl'] as String?,
        splashImageUrl: json['splashImageUrl'] as String?,
        supportEmail: json['supportEmail'] as String?,
        termsUrl: json['termsUrl'] as String?,
        privacyUrl: json['privacyUrl'] as String?,
        maintenanceMode: json['maintenanceMode'] as bool? ?? false,
        googleMapsApiKey: json['googleMapsApiKey'] as String?,
        developerUpiId: json['developerUpiId'] as String?,
        developerQrCodeUrl: json['developerQrCodeUrl'] as String?,
        developerSupportNote: json['developerSupportNote'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

class AdminBrandingUpdateRequest {
  const AdminBrandingUpdateRequest({
    required this.appName,
    this.tagline,
    required this.primaryColor,
    this.logoUrl,
    this.splashImageUrl,
    this.supportEmail,
    this.termsUrl,
    this.privacyUrl,
    this.maintenanceMode,
    this.googleMapsApiKey,
    this.developerUpiId,
    this.developerQrCodeUrl,
    this.developerSupportNote,
  });

  final String appName;
  final String? tagline;
  final String primaryColor;
  final String? logoUrl;
  final String? splashImageUrl;
  final String? supportEmail;
  final String? termsUrl;
  final String? privacyUrl;
  final bool? maintenanceMode;
  final String? googleMapsApiKey;
  final String? developerUpiId;
  final String? developerQrCodeUrl;
  final String? developerSupportNote;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'appName': appName,
      'primaryColor': primaryColor,
    };
    if (tagline != null) map['tagline'] = tagline;
    if (logoUrl != null) map['logoUrl'] = logoUrl;
    if (splashImageUrl != null) map['splashImageUrl'] = splashImageUrl;
    if (supportEmail != null) map['supportEmail'] = supportEmail;
    if (termsUrl != null) map['termsUrl'] = termsUrl;
    if (privacyUrl != null) map['privacyUrl'] = privacyUrl;
    if (maintenanceMode != null) map['maintenanceMode'] = maintenanceMode;
    if (googleMapsApiKey != null) map['googleMapsApiKey'] = googleMapsApiKey;
    if (developerUpiId != null) map['developerUpiId'] = developerUpiId;
    if (developerQrCodeUrl != null) map['developerQrCodeUrl'] = developerQrCodeUrl;
    if (developerSupportNote != null) map['developerSupportNote'] = developerSupportNote;
    return map;
  }
}
