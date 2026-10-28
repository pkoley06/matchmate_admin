import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/admin_room_models.dart';
import 'admin_rooms_api.dart';

final adminRoomsRepositoryProvider = Provider<AdminRoomsRepository>(
  (ref) => AdminRoomsRepository(ref.watch(adminRoomsApiProvider)),
);

class AdminRoomsRepository {
  AdminRoomsRepository(this._api);

  final AdminRoomsApi _api;

  Future<AdminRoomPage> listRooms({
    String? search,
    bool? available,
    int page = 0,
    int size = 20,
  }) => _api.getRooms(search: search, available: available, page: page, size: size);

  Future<AdminRoomDetail> getRoom(int id) => _api.getRoom(id);

  Future<AdminRoomDetail> createRoom(AdminRoomCreateRequest request) =>
      _api.createRoom(request);

  Future<AdminRoomDetail> updateRoom(
    int id,
    AdminRoomUpdateRequest request,
  ) => _api.updateRoom(id, request);

  Future<AdminRoomDetail> setAvailable(int id, bool available) =>
      _api.setAvailable(id, available);

  Future<void> deleteRoom(int id) => _api.deleteRoom(id);
}
