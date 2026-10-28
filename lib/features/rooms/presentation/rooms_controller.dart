import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_rooms_repository.dart';
import '../domain/admin_room_models.dart';

class RoomsState {
  const RoomsState({
    required this.pageData,
    this.searchQuery = '',
    this.availableFilter,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  final AdminRoomPage? pageData;
  final String searchQuery;
  final bool? availableFilter;
  final int currentPage;
  final bool isLoading;
  final String? error;

  RoomsState copyWith({
    AdminRoomPage? pageData,
    String? searchQuery,
    bool? availableFilter,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) =>
      RoomsState(
        pageData: pageData ?? this.pageData,
        searchQuery: searchQuery ?? this.searchQuery,
        availableFilter: availableFilter ?? this.availableFilter,
        currentPage: currentPage ?? this.currentPage,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final roomsControllerProvider =
    NotifierProvider<RoomsController, RoomsState>(RoomsController.new);

class RoomsController extends Notifier<RoomsState> {
  AdminRoomsRepository get _repository => ref.read(adminRoomsRepositoryProvider);

  @override
  RoomsState build() {
    Future.microtask(loadRooms);
    return const RoomsState(pageData: null, isLoading: true);
  }

  Future<void> loadRooms({String? search, bool? available, int? page}) async {
    final query = search ?? state.searchQuery;
    final avail = available ?? state.availableFilter;
    final pageNum = page ?? state.currentPage;

    state = state.copyWith(
      isLoading: true,
      searchQuery: query,
      availableFilter: avail,
      currentPage: pageNum,
      error: null,
    );

    try {
      final result = await _repository.listRooms(
        search: query.isEmpty ? null : query,
        available: avail,
        page: pageNum,
        size: 15,
      );
      state = state.copyWith(
        pageData: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleAvailability(int roomId, bool currentAvailable) async {
    try {
      final updated = await _repository.setAvailable(roomId, !currentAvailable);
      if (state.pageData != null) {
        final updatedContent = state.pageData!.content.map((r) {
          if (r.id == roomId) {
            return AdminRoomSummary(
              id: r.id,
              title: r.title,
              hostUserId: r.hostUserId,
              hostUserName: r.hostUserName,
              listingType: r.listingType,
              roomType: r.roomType,
              furnishingStatus: r.furnishingStatus,
              rentAmount: r.rentAmount,
              depositAmount: r.depositAmount,
              localityName: r.localityName,
              city: r.city,
              isAvailable: updated.isAvailable,
              photoUrls: r.photoUrls,
              createdAt: r.createdAt,
            );
          }
          return r;
        }).toList();

        state = state.copyWith(
          pageData: AdminRoomPage(
            content: updatedContent,
            page: state.pageData!.page,
            size: state.pageData!.size,
            totalElements: state.pageData!.totalElements,
            totalPages: state.pageData!.totalPages,
            isLast: state.pageData!.isLast,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    try {
      await _repository.deleteRoom(roomId);
      await loadRooms();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<AdminRoomDetail?> fetchDetail(int roomId) async {
    try {
      return await _repository.getRoom(roomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createRoom(AdminRoomCreateRequest request) async {
    try {
      await _repository.createRoom(request);
      await loadRooms(page: 0);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
