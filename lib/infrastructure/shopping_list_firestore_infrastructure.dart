import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _shoppingListsCollection = 'shopping_lists';
  static const String _shoppingItemsCollection = 'shopping_items';

  /// スペース内の買い物リスト一覧を取得
  Future<List<Map<String, dynamic>>> getSpaceShoppingLists(
      String spaceId) async {
    try {
      final query = await _firestore
          .collection(_shoppingListsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      final lists = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final listData = {
          'id': doc.id,
          ...doc.data(),
        };

        // 各リストのアイテム数を取得
        final itemsCount = await getShoppingListItemsCount(doc.id);
        listData['items_count'] = itemsCount;

        lists.add(listData);
      }

      return lists;
    } catch (e) {
      throw Exception('買い物リスト一覧の取得に失敗しました: $e');
    }
  }

  /// 買い物リストを追加
  Future<String> addShoppingList({
    required String spaceId,
    required String name,
    required String createdBy,
    String? description,
  }) async {
    try {
      final listRef = _firestore.collection(_shoppingListsCollection).doc();

      await listRef.set({
        'id': listRef.id,
        'space_id': spaceId,
        'name': name,
        'description': description ?? '',
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      return listRef.id;
    } catch (e) {
      throw Exception('買い物リストの追加に失敗しました: $e');
    }
  }

  /// 買い物リストを更新
  Future<bool> updateShoppingList({
    required String listId,
    required String spaceId,
    required String userId,
    String? name,
    String? description,
  }) async {
    try {
      // リストの存在確認と権限チェック
      final listDoc = await _firestore
          .collection(_shoppingListsCollection)
          .doc(listId)
          .get();

      if (!listDoc.exists) {
        throw Exception('買い物リストが見つかりません');
      }

      final listData = listDoc.data()!;
      if (listData['space_id'] != spaceId) {
        throw Exception('このスペースの買い物リストではありません');
      }

      // 更新データを準備
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      await _firestore
          .collection(_shoppingListsCollection)
          .doc(listId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('買い物リストの更新に失敗しました: $e');
    }
  }

  /// 買い物リストを削除
  Future<bool> deleteShoppingList({
    required String listId,
    required String spaceId,
    required String userId,
  }) async {
    try {
      // リストの存在確認と権限チェック
      final listDoc = await _firestore
          .collection(_shoppingListsCollection)
          .doc(listId)
          .get();

      if (!listDoc.exists) {
        throw Exception('買い物リストが見つかりません');
      }

      final listData = listDoc.data()!;
      if (listData['space_id'] != spaceId) {
        throw Exception('このスペースの買い物リストではありません');
      }

      final batch = _firestore.batch();

      // リストを非アクティブに設定
      batch.update(
        _firestore.collection(_shoppingListsCollection).doc(listId),
        {
          'is_active': false,
          'deleted_at': FieldValue.serverTimestamp(),
          'deleted_by': userId,
        },
      );

      // 関連するアイテムも非アクティブに設定
      final items = await _firestore
          .collection(_shoppingItemsCollection)
          .where('shopping_list_id', isEqualTo: listId)
          .where('is_active', isEqualTo: true)
          .get();

      for (final item in items.docs) {
        batch.update(item.reference, {
          'is_active': false,
          'deleted_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('買い物リストの削除に失敗しました: $e');
    }
  }

  /// 特定の買い物リストを取得
  Future<Map<String, dynamic>?> getShoppingList(String listId) async {
    try {
      final doc = await _firestore
          .collection(_shoppingListsCollection)
          .doc(listId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      throw Exception('買い物リストの取得に失敗しました: $e');
    }
  }

  // === 買い物アイテム関連 ===

  /// 買い物リストのアイテム一覧を取得
  Future<List<Map<String, dynamic>>> getShoppingListItems(String listId) async {
    try {
      final query = await _firestore
          .collection(_shoppingItemsCollection)
          .where('shopping_list_id', isEqualTo: listId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at')
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('買い物アイテム一覧の取得に失敗しました: $e');
    }
  }

  /// 買い物リストのアイテム数を取得
  Future<int> getShoppingListItemsCount(String listId) async {
    try {
      final query = await _firestore
          .collection(_shoppingItemsCollection)
          .where('shopping_list_id', isEqualTo: listId)
          .where('is_active', isEqualTo: true)
          .get();

      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// 買い物アイテムを追加
  Future<String> addShoppingItem({
    required String listId,
    required String itemName,
    required double quantity,
    required String unit,
    double? price,
  }) async {
    try {
      final itemRef = _firestore.collection(_shoppingItemsCollection).doc();

      await itemRef.set({
        'id': itemRef.id,
        'shopping_list_id': listId,
        'item_name': itemName,
        'quantity': quantity,
        'price': price ?? 0,
        'unit': unit,
        'is_completed': false,
        'completed_by': null,
        'completed_at': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return itemRef.id;
    } catch (e) {
      throw Exception('買い物アイテムの追加に失敗しました: $e');
    }
  }

  /// 買い物アイテムを更新
  Future<bool> updateShoppingItem({
    required String itemId,
    String? itemName,
    double? quantity,
    String? unit,
    double? price,
    bool? isCompleted,
    String? completedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (itemName != null) updateData['item_name'] = itemName;
      if (quantity != null) updateData['quantity'] = quantity;
      if (unit != null) updateData['unit'] = unit;
      if (price != null) updateData['price'] = price;
      if (isCompleted != null) {
        updateData['is_completed'] = isCompleted;
        if (isCompleted) {
          updateData['completed_by'] = completedBy;
          updateData['completed_at'] = FieldValue.serverTimestamp();
        } else {
          updateData['completed_by'] = null;
          updateData['completed_at'] = null;
        }
      }

      await _firestore
          .collection(_shoppingItemsCollection)
          .doc(itemId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('買い物アイテムの更新に失敗しました: $e');
    }
  }

  /// 買い物アイテムを削除
  Future<bool> deleteShoppingItem(String itemId) async {
    try {
      await _firestore.collection(_shoppingItemsCollection).doc(itemId).update({
        'is_active': false,
        'deleted_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('買い物アイテムの削除に失敗しました: $e');
    }
  }

  /// アイテムの完了状態を切り替え
  Future<bool> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    String? userId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'is_completed': isCompleted,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isCompleted) {
        updateData['completed_by'] = userId;
        updateData['completed_at'] = FieldValue.serverTimestamp();
      } else {
        updateData['completed_by'] = null;
        updateData['completed_at'] = null;
      }

      await _firestore
          .collection(_shoppingItemsCollection)
          .doc(itemId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('アイテム完了状態の更新に失敗しました: $e');
    }
  }

  /// 買い物リストの進捗情報を取得
  Future<Map<String, int>> getShoppingListProgress(String listId) async {
    try {
      final items = await getShoppingListItems(listId);

      final totalItems = items.length;
      final completedItems =
          items.where((item) => item['is_completed'] == true).length;

      return {
        'total': totalItems,
        'completed': completedItems,
        'remaining': totalItems - completedItems,
      };
    } catch (e) {
      throw Exception('買い物リスト進捗の取得に失敗しました: $e');
    }
  }

  /// 買い物リストの合計金額を計算
  Future<double> calculateShoppingListTotal(String listId) async {
    try {
      final items = await getShoppingListItems(listId);

      double total = 0;
      for (final item in items) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 1;
        total += price * quantity;
      }

      return total;
    } catch (e) {
      throw Exception('買い物リスト合計金額の計算に失敗しました: $e');
    }
  }
}
