import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_blocks_api.dart';

class BlocksState {
  const BlocksState({
    this.blocks = const [],
    this.totalElements = 0,
    this.totalPages = 0,
    this.page = 0,
    this.isLoading = true,
    this.error,
  });

  final List<AdminBlock> blocks;
  final int totalElements;
  final int totalPages;
  final int page;
  final bool isLoading;
  final String? error;

  BlocksState copyWith({bool? isLoading, String? error}) => BlocksState(
        blocks: blocks,
        totalElements: totalElements,
        totalPages: totalPages,
        page: page,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final blocksControllerProvider =
    NotifierProvider<BlocksController, BlocksState>(BlocksController.new);

class BlocksController extends Notifier<BlocksState> {
  AdminBlocksApi get _api => ref.read(adminBlocksApiProvider);

  @override
  BlocksState build() {
    Future.microtask(() => load());
    return const BlocksState();
  }

  Future<void> load({int page = 0}) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.list(page: page);
      state = BlocksState(
        blocks: res.content,
        totalElements: res.totalElements,
        totalPages: res.totalPages,
        page: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns null on success, or the error message.
  Future<String?> remove(AdminBlock block) async {
    try {
      await _api.remove(block.blockerId, block.blockedId);
      await load(page: state.page);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
