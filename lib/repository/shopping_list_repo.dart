import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/shopping_list_firestore_infrastructure.dart';
import '../models/shopping_list_model.dart';

final shoppingListRepoProvider = Provider<ShoppingListRepo>(
  (ref) => ShoppingListRepo(),
);

class ShoppingListRepo {
  final ShoppingListFirestoreInfrastructure _infrastructure =
      ShoppingListFirestoreInfrastructure();

  /// 買い物リストグループを作成
  Future<String> createGroup({
    required String spaceId,
    required String groupName,
    required String createdBy,
  }) async {
    return await _infrastructure.createGroup(
      spaceId: spaceId,
      groupName: groupName,
      createdBy: createdBy,
    );
  }

  /// スペース内の買い物リストグループ一覧を取得
  Future<List<ShoppingListGroupModel>> getGroupsBySpace(String spaceId) async {
    return await _infrastructure.getGroupsBySpace(spaceId);
  }

  /// 買い物リストグループの詳細を取得
  Future<ShoppingListGroupModel?> getGroupById(String groupId) async {
    return await _infrastructure.getGroupById(groupId);
  }

  /// 買い物リストグループを更新
  Future<bool> updateGroup({
    required String groupId,
    required String groupName,
  }) async {
    return await _infrastructure.updateGroup(
      groupId: groupId,
      groupName: groupName,
    );
  }

  /// 買い物リストグループを削除
  Future<bool> deleteGroup(String groupId) async {
    return await _infrastructure.deleteGroup(groupId);
  }

  /// 買い物リストアイテムを作成
  Future<String> createItem({
    required String groupId,
    required String itemName,
    double? amount,
    required String createdBy,
  }) async {
    return await _infrastructure.createItem(
      groupId: groupId,
      itemName: itemName,
      amount: amount,
      createdBy: createdBy,
    );
  }

  /// グループ内の買い物リストアイテム一覧を取得
  Future<List<ShoppingListItemModel>> getItemsByGroup(String groupId) async {
    return await _infrastructure.getItemsByGroup(groupId);
  }

  /// 買い物リストアイテムを更新
  Future<bool> updateItem({
    required String itemId,
    String? itemName,
    bool? isPurchased,
    double? amount,
  }) async {
    return await _infrastructure.updateItem(
      itemId: itemId,
      itemName: itemName,
      isPurchased: isPurchased,
      amount: amount,
    );
  }

  /// 買い物リストアイテムを削除
  Future<bool> deleteItem(String itemId) async {
    return await _infrastructure.deleteItem(itemId);
  }

  /// 購入済み状態を切り替え
  Future<bool> togglePurchaseStatus(String itemId, bool isPurchased) async {
    return await _infrastructure.togglePurchaseStatus(itemId, isPurchased);
  }
}
