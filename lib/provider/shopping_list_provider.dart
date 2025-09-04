import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/shopping_list_firestore_infrastructure.dart';
import '../models/shopping_list_model.dart';
import '../provider/firestore_space_provider.dart';

// 買い物リストインフラストラクチャのプロバイダー
final shoppingListInfrastructureProvider =
    Provider<ShoppingListFirestoreInfrastructure>((ref) {
  return ShoppingListFirestoreInfrastructure();
});

// 買い物リスト状態のプロバイダー
class ShoppingListState {
  final List<ShoppingListGroupModel> groups;
  final List<ShoppingListItemModel> items;
  final ShoppingListGroupModel? selectedGroup;
  final bool isLoading;
  final String? error;

  ShoppingListState({
    this.groups = const [],
    this.items = const [],
    this.selectedGroup,
    this.isLoading = false,
    this.error,
  });

  ShoppingListState copyWith({
    List<ShoppingListGroupModel>? groups,
    List<ShoppingListItemModel>? items,
    ShoppingListGroupModel? selectedGroup,
    bool? isLoading,
    String? error,
  }) {
    return ShoppingListState(
      groups: groups ?? this.groups,
      items: items ?? this.items,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 買い物リストプロバイダー
class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  final ShoppingListFirestoreInfrastructure _infrastructure;
  final Ref _ref;

  ShoppingListNotifier(this._infrastructure, this._ref)
      : super(ShoppingListState());

  // 買い物リストグループ一覧を読み込み
  Future<void> loadGroups() async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      state = state.copyWith(error: 'スペースが選択されていません');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _infrastructure.getGroupsBySpace(currentSpace.id);
      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // グループを選択してアイテム一覧を読み込み
  Future<void> selectGroupAndLoadItems(ShoppingListGroupModel group) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _infrastructure.getItemsByGroup(group.id);
      state = state.copyWith(
        selectedGroup: group,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 買い物リストグループを作成
  Future<String?> createGroup({
    required String groupName,
    required String createdBy,
  }) async {
    final spaceState = _ref.read(firestoreSpacesProvider);
    final currentSpace = spaceState?.currentSpace;

    if (currentSpace == null) {
      state = state.copyWith(error: 'スペースが選択されていません');
      return null;
    }

    try {
      final groupId = await _infrastructure.createGroup(
        spaceId: currentSpace.id,
        groupName: groupName,
        createdBy: createdBy,
      );

      // グループ一覧を再読み込み
      await loadGroups();
      return groupId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // 買い物リストグループを更新
  Future<void> updateGroup({
    required String groupId,
    required String groupName,
  }) async {
    try {
      await _infrastructure.updateGroup(
        groupId: groupId,
        groupName: groupName,
      );

      // グループ一覧を再読み込み
      await loadGroups();

      // 現在選択中のグループも更新
      if (state.selectedGroup?.id == groupId) {
        final updatedGroup = state.selectedGroup!.copyWith(
          groupName: groupName,
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(selectedGroup: updatedGroup);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 買い物リストグループを削除
  Future<void> deleteGroup(String groupId) async {
    try {
      await _infrastructure.deleteGroup(groupId);

      // グループ一覧を再読み込み
      await loadGroups();

      // 削除されたグループが選択中だった場合は選択を解除
      if (state.selectedGroup?.id == groupId) {
        state = state.copyWith(
          selectedGroup: null,
          items: [],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 買い物リストアイテムを作成
  Future<String?> createItem({
    required String itemName,
    double? amount,
    required String createdBy,
  }) async {
    if (state.selectedGroup == null) {
      state = state.copyWith(error: 'グループが選択されていません');
      return null;
    }

    try {
      final itemId = await _infrastructure.createItem(
        groupId: state.selectedGroup!.id,
        itemName: itemName,
        amount: amount,
        createdBy: createdBy,
      );

      // アイテム一覧を再読み込み
      await selectGroupAndLoadItems(state.selectedGroup!);
      return itemId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // 特定のグループにアイテムを作成
  Future<String?> createItemForGroup({
    required String groupId,
    required String itemName,
    double? amount,
    required String createdBy,
  }) async {
    try {
      final itemId = await _infrastructure.createItem(
        groupId: groupId,
        itemName: itemName,
        amount: amount,
        createdBy: createdBy,
      );
      return itemId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // 買い物リストアイテムを更新
  Future<void> updateItem({
    required String itemId,
    String? itemName,
    bool? isPurchased,
    double? amount,
  }) async {
    try {
      await _infrastructure.updateItem(
        itemId: itemId,
        itemName: itemName,
        isPurchased: isPurchased,
        amount: amount,
      );

      // アイテム一覧を再読み込み
      if (state.selectedGroup != null) {
        await selectGroupAndLoadItems(state.selectedGroup!);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 買い物リストアイテムを削除
  Future<void> deleteItem(String itemId) async {
    try {
      await _infrastructure.deleteItem(itemId);

      // アイテム一覧を再読み込み
      if (state.selectedGroup != null) {
        await selectGroupAndLoadItems(state.selectedGroup!);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 購入済み状態を切り替え
  Future<void> togglePurchaseStatus(String itemId, bool isPurchased) async {
    try {
      await _infrastructure.togglePurchaseStatus(itemId, isPurchased);

      // アイテム一覧を再読み込み
      if (state.selectedGroup != null) {
        await selectGroupAndLoadItems(state.selectedGroup!);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 選択中のグループをクリア
  void clearSelectedGroup() {
    state = state.copyWith(
      selectedGroup: null,
      items: [],
    );
  }

  // 特定のグループのアイテムを読み込み
  Future<List<ShoppingListItemModel>> getItemsForGroup(String groupId) async {
    try {
      return await _infrastructure.getItemsByGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // 特定のグループのアイテムを読み込み（状態更新なし）
  Future<void> loadItemsForGroup(String groupId) async {
    try {
      await _infrastructure.getItemsByGroup(groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// 買い物リストプロバイダー
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, ShoppingListState>((ref) {
  final infrastructure = ref.watch(shoppingListInfrastructureProvider);
  return ShoppingListNotifier(infrastructure, ref);
});
