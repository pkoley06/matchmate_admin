import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final adminTokenStorageProvider = Provider<AdminTokenStorage>(
  (ref) => AdminTokenStorage(const FlutterSecureStorage()),
);

/// Holds the admin console's own session, separate from (and never mixed
/// with) the mobile app's token - this app never talks to mobile-user
/// endpoints. Persists the whole login response (not just the token) so a
/// browser refresh can restore "who is logged in" without a dedicated
/// "whoami" endpoint.
class AdminTokenStorage {
  AdminTokenStorage(this._storage);

  static const _sessionKey = 'matchmate_admin_session';

  final FlutterSecureStorage _storage;
  Map<String, dynamic>? _cached;

  Future<String?> readAccessToken() async {
    final session = await _readSession();
    return session?['accessToken'] as String?;
  }

  Future<Map<String, dynamic>?> readSession() => _readSession();

  Future<void> saveSession(Map<String, dynamic> session) async {
    _cached = session;
    await _storage.write(key: _sessionKey, value: jsonEncode(session));
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _sessionKey);
  }

  Future<Map<String, dynamic>?> _readSession() async {
    if (_cached != null) return _cached;
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    return _cached = jsonDecode(raw) as Map<String, dynamic>;
  }
}
