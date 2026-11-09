import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_announcements_api.dart';
import '../domain/admin_announcement_models.dart';

final announcementsControllerProvider = AsyncNotifierProvider<
    AnnouncementsController, List<AdminAnnouncement>>(
  AnnouncementsController.new,
);

class AnnouncementsController extends AsyncNotifier<List<AdminAnnouncement>> {
  @override
  Future<List<AdminAnnouncement>> build() async {
    return ref.watch(adminAnnouncementsApiProvider).list();
  }

  Future<bool> broadcast(AdminAnnouncementBroadcastRequest request) async {
    try {
      final sent =
          await ref.read(adminAnnouncementsApiProvider).broadcast(request);
      final current = state.value ?? [];
      state = AsyncData([sent, ...current]);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminAnnouncementsApiProvider).list(),
    );
  }
}
