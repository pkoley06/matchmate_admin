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
    this.developerUpiAmount,
    this.developerUpiNote,
    this.activeIcon,
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

  /// Rupees pre-filled in the payer's UPI app; null leaves the amount blank
  /// for the payer to type.
  final int? developerUpiAmount;

  /// The note / remark pre-filled in the payer's UPI app.
  final String? developerUpiNote;

  /// Active launcher icon (e.g. "default", "diwali").
  final String? activeIcon;
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
        developerUpiAmount: (json['developerUpiAmount'] as num?)?.toInt(),
        developerUpiNote: json['developerUpiNote'] as String?,
        activeIcon: json['activeIcon'] as String? ?? 'default',
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
    this.developerUpiAmount,
    this.developerUpiNote,
    this.activeIcon,
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

  /// 0 clears the amount (the payer types their own).
  final int? developerUpiAmount;
  final String? developerUpiNote;
  final String? activeIcon;

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
    if (developerUpiAmount != null) map['developerUpiAmount'] = developerUpiAmount;
    if (developerUpiNote != null) map['developerUpiNote'] = developerUpiNote;
    if (activeIcon != null) map['activeIcon'] = activeIcon;
    return map;
  }
}
