import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_comment_models.dart';
import 'admin_comments_api.dart';

final adminCommentsRepositoryProvider = Provider<AdminCommentsRepository>(
  (ref) => AdminCommentsRepository(ref.watch(adminCommentsApiProvider)),
);

class AdminCommentsRepository {
  AdminCommentsRepository(this._api);

  final AdminCommentsApi _api;

  Future<AdminCommentPage> list({
    String? search,
    String? listingId,
    int page = 0,
    int size = 20,
  }) =>
      _api.list(search: search, listingId: listingId, page: page, size: size);

  Future<AdminComment> getById(String id) => _api.getById(id);

  Future<void> delete(String id) => _api.delete(id);
}
