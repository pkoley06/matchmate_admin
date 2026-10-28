import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_auth_repository.dart';
import '../domain/admin_session.dart';

// ---------- State ----------

sealed class AdminAuthState {
  const AdminAuthState();
}

/// App just started; restoring a saved session (if any).
final class AdminAuthInitializing extends AdminAuthState {
  const AdminAuthInitializing();
}

final class AdminUnauthenticated extends AdminAuthState {
  const AdminUnauthenticated({this.errorMessage});
  final String? errorMessage;
}

final class AdminAuthenticated extends AdminAuthState {
  const AdminAuthenticated(this.session);
  final AdminSession session;
}

// ---------- Controller ----------

final adminAuthControllerProvider =
    NotifierProvider<AdminAuthController, AdminAuthState>(
      AdminAuthController.new,
    );

class AdminAuthController extends Notifier<AdminAuthState> {
  AdminAuthRepository get _repo => ref.read(adminAuthRepositoryProvider);

  @override
  AdminAuthState build() {
    Future.microtask(_restoreSession);
    return const AdminAuthInitializing();
  }

  Future<void> _restoreSession() async {
    final session = await _repo.restoreSession();
    state = session == null
        ? const AdminUnauthenticated()
        : AdminAuthenticated(session);
  }

  Future<void> login({required String username, required String password}) async {
    try {
      final session = await _repo.login(username: username, password: password);
      state = AdminAuthenticated(session);
    } on ApiException catch (e) {
      state = AdminUnauthenticated(errorMessage: e.message);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AdminUnauthenticated();
  }
}
