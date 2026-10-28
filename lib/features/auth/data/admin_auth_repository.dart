import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/admin_token_storage.dart';
import '../domain/admin_session.dart';
import 'admin_auth_api.dart';

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>(
  (ref) => AdminAuthRepository(
    authApi: ref.watch(adminAuthApiProvider),
    tokenStorage: ref.watch(adminTokenStorageProvider),
  ),
);

class AdminAuthRepository {
  AdminAuthRepository({required this._authApi, required this._tokenStorage});

  final AdminAuthApi _authApi;
  final AdminTokenStorage _tokenStorage;

  Future<AdminSession> login({
    required String username,
    required String password,
  }) async {
    final session = await _authApi.login(
      username: username,
      password: password,
    );
    await _tokenStorage.saveSession({
      'accessToken': session.accessToken,
      'expiresIn': session.expiresInMs,
      'adminId': session.adminId,
      'username': session.username,
      'displayName': session.displayName,
    });
    return session;
  }

  /// Restores the session saved on a previous login (e.g. after a browser
  /// refresh). There's no "whoami" endpoint yet, so this is optimistic - the
  /// first real admin request's 401 (handled by AuthInterceptor) signs out a
  /// stale/expired token.
  Future<AdminSession?> restoreSession() async {
    final json = await _tokenStorage.readSession();
    if (json == null) return null;
    return AdminSession.fromJson(json);
  }

  Future<void> signOut() async {
    await _tokenStorage.clear();
  }
}
