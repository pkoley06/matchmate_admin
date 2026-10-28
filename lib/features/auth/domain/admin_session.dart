class AdminSession {
  const AdminSession({
    required this.accessToken,
    required this.expiresInMs,
    required this.adminId,
    required this.username,
    required this.displayName,
  });

  final String accessToken;
  final int expiresInMs;
  final int adminId;
  final String username;
  final String displayName;

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
    accessToken: json['accessToken'] as String,
    expiresInMs: (json['expiresIn'] as num).toInt(),
    adminId: (json['adminId'] as num).toInt(),
    username: json['username'] as String,
    displayName: json['displayName'] as String,
  );
}
