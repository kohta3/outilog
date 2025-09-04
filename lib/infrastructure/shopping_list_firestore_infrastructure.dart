import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list_model.dart';

class ShoppingListFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // コレクション名
  static const String _groupsCollection = 'shopping_list_groups';
  static const String _itemsCollection = 'shopping_list_items';

  /// 買い物リストグループを作成
  Future<String> createGroup({
    required String spaceId,
    required String groupName,
    required String createdBy,
  }) async {
    try {
      final groupRef = _firestore.collection(_groupsCollection).doc();
      final groupData = {
        'id': groupRef.id,
        'space_id': spaceId,
        'group_name': groupName,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      };

      await groupRef.set(groupData);
      return groupRef.id;
    } catch (e) {
      throw Exception('買い物リストグループの作成に失敗しました: $e');
    }
  }

  /// スペース内の買い物リストグループ一覧を取得
  Future<List<ShoppingListGroupModel>> getGroupsBySpace(String spaceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_groupsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ShoppingListGroupModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('買い物リストグループ一覧の取得に失敗しました: $e');
    }
  }

  /// 買い物リストグループの詳細を取得
  Future<ShoppingListGroupModel?> getGroupById(String groupId) async {
    try {
      final doc =
          await _firestore.collection(_groupsCollection).doc(groupId).get();

      if (!doc.exists) {
        return null;
      }

      return ShoppingListGroupModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('買い物リストグループの取得に失敗しました: $e');
    }
  }

  /// 買い物リストグループを更新
  Future<bool> updateGroup({
    required String groupId,
    required String groupName,
  }) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'group_name': groupName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('買い物リストグループの更新に失敗しました: $e');
    }
  }

  /// 買い物リストグループを削除
  Future<bool> deleteGroup(String groupId) async {
    try {
      final batch = _firestore.batch();

      // グループを非アクティブに設定
      final groupRef = _firestore.collection(_groupsCollection).doc(groupId);
      batch.update(groupRef, {
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // グループに紐づくアイテムも非アクティブに設定
      final itemsQuery = await _firestore
          .collection(_itemsCollection)
          .where('group_id', isEqualTo: groupId)
          .where('is_active', isEqualTo: true)
          .get();

      for (final itemDoc in itemsQuery.docs) {
        batch.update(itemDoc.reference, {
          'is_active': false,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('買い物リストグループの削除に失敗しました: $e');
    }
  }

  /// 買い物リストアイテムを作成
  Future<String> createItem({
    required String groupId,
    required String itemName,
    double? amount,
    required String createdBy,
  }) async {
    try {
      final itemRef = _firestore.collection(_itemsCollection).doc();
      final itemData = {
        'id': itemRef.id,
        'group_id': groupId,
        'item_name': itemName,
        'is_purchased': false,
        'amount': amount,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      };

      await itemRef.set(itemData);
      return itemRef.id;
    } catch (e) {
      throw Exception('買い物リストアイテムの作成に失敗しました: $e');
    }
  }

  /// グループ内の買い物リストアイテム一覧を取得
  Future<List<ShoppingListItemModel>> getItemsByGroup(String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_itemsCollection)
          .where('group_id', isEqualTo: groupId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ShoppingListItemModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('買い物リストアイテム一覧の取得に失敗しました: $e');
    }
  }

  /// 買い物リストアイテムを更新
  Future<bool> updateItem({
    required String itemId,
    String? itemName,
    bool? isPurchased,
    double? amount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (itemName != null) updateData['item_name'] = itemName;
      if (isPurchased != null) updateData['is_purchased'] = isPurchased;
      if (amount != null) updateData['amount'] = amount;

      await _firestore
          .collection(_itemsCollection)
          .doc(itemId)
          .update(updateData);
      return true;
    } catch (e) {
      throw Exception('買い物リストアイテムの更新に失敗しました: $e');
    }
  }

  /// 買い物リストアイテムを削除
  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestore.collection(_itemsCollection).doc(itemId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('買い物リストアイテムの削除に失敗しました: $e');
    }
  }

  /// 購入済み状態を切り替え
  Future<bool> togglePurchaseStatus(String itemId, bool isPurchased) async {
    try {
      await _firestore.collection(_itemsCollection).doc(itemId).update({
        'is_purchased': isPurchased,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('購入状態の更新に失敗しました: $e');
    }
  }
}
