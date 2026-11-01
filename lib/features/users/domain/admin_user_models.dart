/// Mirrors backend `AccountStatus`.
enum AdminAccountStatus {
  active('ACTIVE', 'Active'),
  disabled('DISABLED', 'Disabled'),
  deleted('DELETED', 'Deleted');

  const AdminAccountStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AdminAccountStatus fromJson(String? value, {required bool isActive}) {
    for (final s in values) {
      if (s.apiValue == value) return s;
    }
    // Older payloads only carry the boolean.
    return isActive ? active : disabled;
  }
}

/// Per-user push categories as the admin sees them (read-only).
class AdminNotificationPreferences {
  const AdminNotificationPreferences({
    this.likesComments = true,
    this.messages = true,
    this.seekersNearby = true,
    this.roomsNearby = true,
    this.updatedAt,
  });

  final bool likesComments;
  final bool messages;
  final bool seekersNearby;
  final bool roomsNearby;
  final DateTime? updatedAt;

  factory AdminNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      AdminNotificationPreferences(
        likesComments: json['notifyLikesComments'] as bool? ?? true,
        messages: json['notifyMessages'] as bool? ?? true,
        seekersNearby: json['notifySeekersNearby'] as bool? ?? true,
        roomsNearby: json['notifyRoomsNearby'] as bool? ?? true,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.fullName,
    this.gender,
    this.age,
    this.lastKnownLocality,
    this.primaryAuthProvider,
    required this.isActive,
    this.accountStatus = AdminAccountStatus.active,
    this.isSuspended = false,
    this.suspendedReason,
    required this.onboardingCompleted,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String? gender;
  final int? age;
  final String? lastKnownLocality;
  final String? primaryAuthProvider;
  final bool isActive;
  final AdminAccountStatus accountStatus;
  final bool isSuspended;
  final String? suspendedReason;
  final bool onboardingCompleted;
  final DateTime? createdAt;

  AdminUserSummary copyWith({
    bool? isActive,
    AdminAccountStatus? accountStatus,
    bool? isSuspended,
    String? suspendedReason,
    bool clearSuspendedReason = false,
  }) =>
      AdminUserSummary(
        id: id,
        fullName: fullName,
        gender: gender,
        age: age,
        lastKnownLocality: lastKnownLocality,
        primaryAuthProvider: primaryAuthProvider,
        isActive: isActive ?? this.isActive,
        accountStatus: accountStatus ?? this.accountStatus,
        isSuspended: isSuspended ?? this.isSuspended,
        suspendedReason: clearSuspendedReason
            ? null
            : (suspendedReason ?? this.suspendedReason),
        onboardingCompleted: onboardingCompleted,
        createdAt: createdAt,
      );

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'] as bool? ?? true;
    return AdminUserSummary(
      id: json['id'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      lastKnownLocality: json['lastKnownLocality'] as String?,
      primaryAuthProvider: json['primaryAuthProvider'] as String?,
      isActive: isActive,
      accountStatus: AdminAccountStatus.fromJson(
        json['accountStatus'] as String?,
        isActive: isActive,
      ),
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspendedReason: json['suspendedReason'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.id,
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    this.age,
    this.avatarUrl,
    this.occupationCategory,
    this.occupationTitle,
    this.bio,
    this.smokingHabit,
    this.dietaryPreference,
    this.sleepSchedule,
    this.cleanlinessLevel,
    this.guestTolerance,
    this.lastKnownLocality,
    this.primaryAuthProvider,
    required this.isActive,
    this.accountStatus = AdminAccountStatus.active,
    this.disabledAt,
    this.isSuspended = false,
    this.suspendedReason,
    required this.onboardingCompleted,
    this.isLookingForRoom,
    this.notificationPreferences = const AdminNotificationPreferences(),
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? gender;
  final String? dateOfBirth;
  final int? age;
  final String? avatarUrl;
  final String? occupationCategory;
  final String? occupationTitle;
  final String? bio;
  final String? smokingHabit;
  final String? dietaryPreference;
  final String? sleepSchedule;
  final String? cleanlinessLevel;
  final String? guestTolerance;
  final String? lastKnownLocality;
  final String? primaryAuthProvider;
  final bool isActive;
  final AdminAccountStatus accountStatus;
  final DateTime? disabledAt;
  final bool isSuspended;
  final String? suspendedReason;
  final bool onboardingCompleted;

  /// Room Finder Mode (`is_room_seeker`), null when the server didn't send it.
  final bool? isLookingForRoom;
  final AdminNotificationPreferences notificationPreferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final isActive = json['isActive'] as bool? ?? true;
    final prefs = json['notificationPreferences'];
    return AdminUserDetail(
      id: json['id'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      age: (json['age'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl'] as String?,
      occupationCategory: json['occupationCategory'] as String?,
      occupationTitle: json['occupationTitle'] as String?,
      bio: json['bio'] as String?,
      smokingHabit: json['smokingHabit'] as String?,
      dietaryPreference: json['dietaryPreference'] as String?,
      sleepSchedule: json['sleepSchedule'] as String?,
      cleanlinessLevel: json['cleanlinessLevel'] as String?,
      guestTolerance: json['guestTolerance'] as String?,
      lastKnownLocality: json['lastKnownLocality'] as String?,
      primaryAuthProvider: json['primaryAuthProvider'] as String?,
      isActive: isActive,
      accountStatus: AdminAccountStatus.fromJson(
        json['accountStatus'] as String?,
        isActive: isActive,
      ),
      disabledAt: json['disabledAt'] != null
          ? DateTime.tryParse(json['disabledAt'] as String)
          : null,
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspendedReason: json['suspendedReason'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      isLookingForRoom: json['isLookingForRoom'] as bool?,
      notificationPreferences: prefs is Map<String, dynamic>
          ? AdminNotificationPreferences.fromJson(prefs)
          : const AdminNotificationPreferences(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class AdminUserPage {
  const AdminUserPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  final List<AdminUserSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  AdminUserPage copyWith({List<AdminUserSummary>? content}) => AdminUserPage(
        content: content ?? this.content,
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
        isLast: isLast,
      );

  factory AdminUserPage.fromJson(Map<String, dynamic> json) => AdminUserPage(
        content: (json['content'] as List<dynamic>? ?? [])
            .map((e) => AdminUserSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 20,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        isLast: json['isLast'] as bool? ?? true,
      );
}

class AdminUserCreateRequest {
  const AdminUserCreateRequest({
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    this.avatarUrl,
    this.occupationCategory,
    this.occupationTitle,
    this.bio,
    this.lastKnownLocality,
    this.smokingHabit,
    this.dietaryPreference,
    this.sleepSchedule,
    this.cleanlinessLevel,
    this.guestTolerance,
  });

  final String fullName;
  final String gender;
  final String dateOfBirth; // yyyy-MM-dd
  final String? avatarUrl;
  final String? occupationCategory;
  final String? occupationTitle;
  final String? bio;
  final String? lastKnownLocality;
  final String? smokingHabit;
  final String? dietaryPreference;
  final String? sleepSchedule;
  final String? cleanlinessLevel;
  final String? guestTolerance;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (occupationCategory != null) 'occupationCategory': occupationCategory,
        if (occupationTitle != null) 'occupationTitle': occupationTitle,
        if (bio != null) 'bio': bio,
        if (lastKnownLocality != null) 'lastKnownLocality': lastKnownLocality,
        if (smokingHabit != null) 'smokingHabit': smokingHabit,
        if (dietaryPreference != null) 'dietaryPreference': dietaryPreference,
        if (sleepSchedule != null) 'sleepSchedule': sleepSchedule,
        if (cleanlinessLevel != null) 'cleanlinessLevel': cleanlinessLevel,
        if (guestTolerance != null) 'guestTolerance': guestTolerance,
      };
}

class AdminUserUpdateRequest {
  const AdminUserUpdateRequest({
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    this.occupationCategory,
    this.occupationTitle,
    this.bio,
    this.lastKnownLocality,
    this.smokingHabit,
    this.dietaryPreference,
    this.sleepSchedule,
    this.cleanlinessLevel,
    this.guestTolerance,
  });

  final String? fullName;
  final String? gender;
  final String? dateOfBirth;
  final String? avatarUrl;
  final String? occupationCategory;
  final String? occupationTitle;
  final String? bio;
  final String? lastKnownLocality;
  final String? smokingHabit;
  final String? dietaryPreference;
  final String? sleepSchedule;
  final String? cleanlinessLevel;
  final String? guestTolerance;

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (occupationCategory != null) 'occupationCategory': occupationCategory,
        if (occupationTitle != null) 'occupationTitle': occupationTitle,
        if (bio != null) 'bio': bio,
        if (lastKnownLocality != null) 'lastKnownLocality': lastKnownLocality,
        if (smokingHabit != null) 'smokingHabit': smokingHabit,
        if (dietaryPreference != null) 'dietaryPreference': dietaryPreference,
        if (sleepSchedule != null) 'sleepSchedule': sleepSchedule,
        if (cleanlinessLevel != null) 'cleanlinessLevel': cleanlinessLevel,
        if (guestTolerance != null) 'guestTolerance': guestTolerance,
      };
}
