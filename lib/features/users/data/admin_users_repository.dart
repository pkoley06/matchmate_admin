import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_user_models.dart';
import 'admin_users_api.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(ref.watch(adminUsersApiProvider)),
);

class AdminUsersRepository {
  AdminUsersRepository(this._api);

  final AdminUsersApi _api;

  Future<AdminUserPage> listUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) => _api.getUsers(search: search, page: page, size: size);

  Future<AdminUserDetail> getUser(int id) => _api.getUser(id);

  Future<AdminUserDetail> createUser(AdminUserCreateRequest request) =>
      _api.createUser(request);

  Future<AdminUserDetail> updateUser(
    int id,
    AdminUserUpdateRequest request,
  ) => _api.updateUser(id, request);

  Future<AdminUserDetail> setActive(int id, bool active) =>
      _api.setActive(id, active);

  Future<AdminUserDetail> setSuspended(int id, bool suspended, {String? reason}) =>
      _api.setSuspended(id, suspended, reason: reason);
}
