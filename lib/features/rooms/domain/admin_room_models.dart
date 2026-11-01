/// Mirrors the backend `GenderPreference` enum. [all] is "open to everyone".
enum AdminGenderPreference {
  all('ALL', 'Open to all genders'),
  male('MALE', 'Male only'),
  female('FEMALE', 'Female only'),
  nonBinary('NON_BINARY', 'Non-binary'),
  other('OTHER', 'Other');

  const AdminGenderPreference(this.apiValue, this.label);
  final String apiValue;
  final String label;

  bool get isOpenToAll => this == all;

  static AdminGenderPreference fromApiValue(String? v) =>
      values.firstWhere((e) => e.apiValue == v, orElse: () => all);
}

class AdminRoomSummary {
  const AdminRoomSummary({
    required this.id,
    required this.title,
    required this.hostUserId,
    this.hostUserName,
    this.listingType,
    this.roomType,
    this.furnishingStatus,
    this.rentAmount,
    this.depositAmount,
    this.localityName,
    this.city,
    this.stateName,
    this.postalCode,
    this.genderPreference = AdminGenderPreference.all,
    required this.isAvailable,
    this.photoUrls = const [],
    this.createdAt,
  });

  final String id;
  final String title;
  final String hostUserId;
  final String? hostUserName;
  final String? listingType;
  final String? roomType;
  final String? furnishingStatus;
  final int? rentAmount;
  final int? depositAmount;
  final String? localityName;
  final String? city;
  final String? stateName;
  final String? postalCode;
  final AdminGenderPreference genderPreference;
  final bool isAvailable;
  final List<String> photoUrls;
  final DateTime? createdAt;

  /// "Koramangala, Bengaluru" — only the parts the geocoder resolved.
  String get placeLabel => [
        if (localityName?.isNotEmpty == true) localityName!,
        if (city?.isNotEmpty == true) city!,
      ].join(', ');

  AdminRoomSummary copyWith({bool? isAvailable}) => AdminRoomSummary(
        id: id,
        title: title,
        hostUserId: hostUserId,
        hostUserName: hostUserName,
        listingType: listingType,
        roomType: roomType,
        furnishingStatus: furnishingStatus,
        rentAmount: rentAmount,
        depositAmount: depositAmount,
        localityName: localityName,
        city: city,
        stateName: stateName,
        postalCode: postalCode,
        genderPreference: genderPreference,
        isAvailable: isAvailable ?? this.isAvailable,
        photoUrls: photoUrls,
        createdAt: createdAt,
      );

  factory AdminRoomSummary.fromJson(Map<String, dynamic> json) =>
      AdminRoomSummary(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        hostUserId: (json['hostUserId'] as String?) ?? '',
        hostUserName: json['hostUserName'] as String?,
        listingType: json['listingType'] as String?,
        roomType: json['roomType'] as String?,
        furnishingStatus: json['furnishingStatus'] as String?,
        rentAmount: (json['rentAmount'] as num?)?.toInt(),
        depositAmount: (json['depositAmount'] as num?)?.toInt(),
        localityName: json['localityName'] as String?,
        city: json['city'] as String?,
        stateName: json['stateName'] as String?,
        postalCode: json['postalCode'] as String?,
        genderPreference: AdminGenderPreference.fromApiValue(
          json['genderPreference'] as String?,
        ),
        isAvailable: json['isAvailable'] as bool? ?? true,
        photoUrls: (json['photoUrls'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

class AdminRoomDetail {
  const AdminRoomDetail({
    required this.id,
    required this.hostUserId,
    this.hostUserName,
    this.hostAvatarUrl,
    this.listingType,
    required this.title,
    this.rentAmount,
    this.depositAmount,
    this.roomType,
    this.furnishingStatus,
    this.latitude,
    this.longitude,
    this.localityName,
    this.city,
    this.stateName,
    this.postalCode,
    this.description,
    this.photoUrls = const [],
    this.moveInDate,
    this.amenities = const [],
    this.genderPreference = AdminGenderPreference.all,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String hostUserId;
  final String? hostUserName;
  final String? hostAvatarUrl;
  final String? listingType;
  final String title;
  final int? rentAmount;
  final int? depositAmount;
  final String? roomType;
  final String? furnishingStatus;
  final double? latitude;
  final double? longitude;
  final String? localityName;
  final String? city;
  final String? stateName;
  final String? postalCode;
  final String? description;
  final List<String> photoUrls;
  final String? moveInDate;
  final List<String> amenities;
  final AdminGenderPreference genderPreference;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get openToAllGenders => genderPreference.isOpenToAll;

  factory AdminRoomDetail.fromJson(Map<String, dynamic> json) =>
      AdminRoomDetail(
        id: json['id'] as String,
        hostUserId: (json['hostUserId'] as String?) ?? '',
        hostUserName: json['hostUserName'] as String?,
        hostAvatarUrl: json['hostAvatarUrl'] as String?,
        listingType: json['listingType'] as String?,
        title: (json['title'] as String?) ?? '',
        rentAmount: (json['rentAmount'] as num?)?.toInt(),
        depositAmount: (json['depositAmount'] as num?)?.toInt(),
        roomType: json['roomType'] as String?,
        furnishingStatus: json['furnishingStatus'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        localityName: json['localityName'] as String?,
        city: json['city'] as String?,
        stateName: json['stateName'] as String?,
        postalCode: json['postalCode'] as String?,
        description: json['description'] as String?,
        photoUrls: (json['photoUrls'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        moveInDate: json['moveInDate'] as String?,
        amenities: (json['amenities'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        genderPreference: json['genderPreference'] != null
            ? AdminGenderPreference.fromApiValue(
                json['genderPreference'] as String?,
              )
            : (json['openToAllGenders'] as bool? ?? true)
                ? AdminGenderPreference.all
                : AdminGenderPreference.other,
        isAvailable: json['isAvailable'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

class AdminRoomPage {
  const AdminRoomPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<AdminRoomSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  AdminRoomPage copyWith({List<AdminRoomSummary>? content}) => AdminRoomPage(
        content: content ?? this.content,
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
        isLast: isLast,
      );

  factory AdminRoomPage.fromJson(Map<String, dynamic> json) => AdminRoomPage(
        content: (json['content'] as List<dynamic>? ?? [])
            .map((e) => AdminRoomSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 20,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        isLast: json['isLast'] as bool? ?? true,
      );
}

class AdminRoomCreateRequest {
  const AdminRoomCreateRequest({
    required this.hostUserId,
    required this.listingType,
    required this.title,
    required this.rentAmount,
    required this.depositAmount,
    required this.roomType,
    required this.furnishingStatus,
    required this.latitude,
    required this.longitude,
    required this.localityName,
    required this.city,
    this.stateName,
    this.postalCode,
    this.description,
    this.photoUrls = const [],
    this.moveInDate,
    this.amenities = const [],
    this.genderPreference = AdminGenderPreference.all,
    this.isAvailable = true,
  });

  final String hostUserId;
  final String listingType;
  final String title;
  final int rentAmount;
  final int depositAmount;
  final String roomType;
  final String furnishingStatus;
  final double latitude;
  final double longitude;
  final String localityName;
  final String city;
  final String? stateName;
  final String? postalCode;
  final String? description;
  final List<String> photoUrls;
  final String? moveInDate;
  final List<String> amenities;
  final AdminGenderPreference genderPreference;
  final bool isAvailable;

  Map<String, dynamic> toJson() => {
        'hostUserId': hostUserId,
        'listingType': listingType,
        'title': title,
        'rentAmount': rentAmount,
        'depositAmount': depositAmount,
        'roomType': roomType,
        'furnishingStatus': furnishingStatus,
        'latitude': latitude,
        'longitude': longitude,
        'localityName': localityName,
        'city': city,
        if (stateName?.isNotEmpty == true) 'stateName': stateName,
        if (postalCode?.isNotEmpty == true) 'postalCode': postalCode,
        if (description != null) 'description': description,
        'photoUrls': photoUrls,
        if (moveInDate != null) 'moveInDate': moveInDate,
        'amenities': amenities,
        'genderPreference': genderPreference.apiValue,
        'isAvailable': isAvailable,
      };
}

class AdminRoomUpdateRequest {
  const AdminRoomUpdateRequest({
    this.listingType,
    this.title,
    this.rentAmount,
    this.depositAmount,
    this.roomType,
    this.furnishingStatus,
    this.latitude,
    this.longitude,
    this.localityName,
    this.city,
    this.stateName,
    this.postalCode,
    this.description,
    this.photoUrls,
    this.moveInDate,
    this.amenities,
    this.genderPreference,
    this.isAvailable,
  });

  final String? listingType;
  final String? title;
  final int? rentAmount;
  final int? depositAmount;
  final String? roomType;
  final String? furnishingStatus;
  final double? latitude;
  final double? longitude;
  final String? localityName;
  final String? city;
  final String? stateName;
  final String? postalCode;
  final String? description;
  final List<String>? photoUrls;
  final String? moveInDate;
  final List<String>? amenities;
  final AdminGenderPreference? genderPreference;
  final bool? isAvailable;

  Map<String, dynamic> toJson() => {
        if (listingType != null) 'listingType': listingType,
        if (title != null) 'title': title,
        if (rentAmount != null) 'rentAmount': rentAmount,
        if (depositAmount != null) 'depositAmount': depositAmount,
        if (roomType != null) 'roomType': roomType,
        if (furnishingStatus != null) 'furnishingStatus': furnishingStatus,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (localityName != null) 'localityName': localityName,
        if (city != null) 'city': city,
        if (stateName != null) 'stateName': stateName,
        if (postalCode != null) 'postalCode': postalCode,
        if (description != null) 'description': description,
        if (photoUrls != null) 'photoUrls': photoUrls,
        if (moveInDate != null) 'moveInDate': moveInDate,
        if (amenities != null) 'amenities': amenities,
        if (genderPreference != null)
          'genderPreference': genderPreference!.apiValue,
        if (isAvailable != null) 'isAvailable': isAvailable,
      };
}
