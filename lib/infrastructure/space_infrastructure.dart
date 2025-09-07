import 'package:cloud_firestore/cloud_firestore.dart';

class SpaceInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // コレクション名
  static const String _spacesCollection = 'spaces';
  static const String _participantsCollection = 'space_participants';

  /// スペースを作成
  Future<String> createSpace({
    required String spaceName,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    int maxParticipants = 10,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1. スペースドキュメントを作成
      final spaceRef = _firestore.collection(_spacesCollection).doc();
      final spaceData = {
        'id': spaceRef.id,
        'space_name': spaceName,
        'owner_id': ownerId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'max_participants': maxParticipants,
        'is_active': true,
        'header_image_url': null,
      };
      batch.set(spaceRef, spaceData);

      // 2. オーナーを参加者として追加
      final participantRef =
          _firestore.collection(_participantsCollection).doc();
      final participantData = {
        'id': participantRef.id,
        'space_id': spaceRef.id,
        'user_id': ownerId,
        'user_name': ownerName,
        'user_email': ownerEmail,
        'role': 'owner',
        'joined_at': FieldValue.serverTimestamp(),
        'is_active': true,
      };
      batch.set(participantRef, participantData);

      // バッチ実行
      await batch.commit();
      return spaceRef.id;
    } catch (e) {
      throw Exception('スペースの作成に失敗しました: $e');
    }
  }

  /// ユーザーが参加しているスペース一覧を取得
  Future<List<Map<String, dynamic>>> getUserSpaces(String userId) async {
    try {
      // 1. ユーザーが参加している空間のIDを取得
      final participantsQuery = await _firestore
          .collection(_participantsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantsQuery.docs.isEmpty) {
        return [];
      }

      // 2. スペースIDのリストを取得
      final spaceIds = participantsQuery.docs
          .map((doc) => doc.data()['space_id'] as String)
          .toList();

      // 3. スペース情報を取得（Firestoreの制限により10個ずつ処理）
      final List<Map<String, dynamic>> allSpaces = [];

      for (int i = 0; i < spaceIds.length; i += 10) {
        final batchIds = spaceIds.skip(i).take(10).toList();
        final spacesQuery = await _firestore
            .collection(_spacesCollection)
            .where(FieldPath.documentId, whereIn: batchIds)
            .where('is_active', isEqualTo: true)
            .get();

        for (final spaceDoc in spacesQuery.docs) {
          final spaceData = spaceDoc.data();

          // 参加者情報を追加
          final participantInfo = participantsQuery.docs
              .firstWhere((p) => p.data()['space_id'] == spaceDoc.id);

          allSpaces.add({
            ...spaceData,
            'user_role': participantInfo.data()['role'],
            'joined_at': participantInfo.data()['joined_at'],
          });
        }
      }

      // 参加日時順でソート
      allSpaces.sort((a, b) {
        final aJoinedAt = a['joined_at'] as Timestamp?;
        final bJoinedAt = b['joined_at'] as Timestamp?;
        if (aJoinedAt == null || bJoinedAt == null) return 0;
        return bJoinedAt.compareTo(aJoinedAt);
      });

      return allSpaces;
    } catch (e) {
      // セキュリティルールエラーの場合は詳細なメッセージを出力
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firestoreのアクセス権限がありません。セキュリティルールを設定してください。');
      }
      throw Exception('スペース一覧の取得に失敗しました: $e');
    }
  }

  /// スペースの詳細情報を取得（参加者リスト含む）
  Future<Map<String, dynamic>?> getSpaceDetails(String spaceId) async {
    try {
      // スペース基本情報を取得
      final spaceDoc =
          await _firestore.collection(_spacesCollection).doc(spaceId).get();

      if (!spaceDoc.exists) {
        return null;
      }

      final spaceData = spaceDoc.data()!;

      // 参加者一覧を取得
      final participantsQuery = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('joined_at')
          .get();

      final participants =
          participantsQuery.docs.map((doc) => doc.data()).toList();

      return {
        ...spaceData,
        'participants': participants,
      };
    } catch (e) {
      throw Exception('スペース詳細の取得に失敗しました: $e');
    }
  }

  /// スペースに参加者を追加
  Future<bool> addParticipant({
    required String spaceId,
    required String userId,
    required String userName,
    required String userEmail,
    String role = 'member',
  }) async {
    try {
      // 1. スペースの存在確認と参加可能人数チェック
      final spaceDoc =
          await _firestore.collection(_spacesCollection).doc(spaceId).get();

      if (!spaceDoc.exists) {
        throw Exception('スペースが見つかりません');
      }

      final spaceData = spaceDoc.data()!;
      final maxParticipants = spaceData['max_participants'] as int;

      // 2. 現在の参加者数をチェック
      final currentParticipants = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (currentParticipants.docs.length >= maxParticipants) {
        throw Exception('参加者数が上限に達しています');
      }

      // 3. 既に参加しているかチェック
      final existingParticipant = currentParticipants.docs
          .where((doc) => doc.data()['user_id'] == userId)
          .toList();

      if (existingParticipant.isNotEmpty) {
        throw Exception('既にこのスペースに参加しています');
      }

      // 4. 参加者を追加
      final participantRef =
          _firestore.collection(_participantsCollection).doc();
      await participantRef.set({
        'id': participantRef.id,
        'space_id': spaceId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'role': role,
        'joined_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      return true;
    } catch (e) {
      throw Exception('参加者の追加に失敗しました: $e');
    }
  }

  /// 参加者のユーザー名を更新
  Future<bool> updateParticipantUserName({
    required String spaceId,
    required String userId,
    required String newUserName,
  }) async {
    try {
      // 参加者を検索
      final participantQuery = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantQuery.docs.isEmpty) {
        throw Exception('参加者が見つかりません');
      }

      // ユーザー名を更新
      await participantQuery.docs.first.reference.update({
        'user_name': newUserName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('DEBUG: Error updating participant user_name: $e');
      return false;
    }
  }

  /// スペースから参加者を削除
  Future<bool> removeParticipant({
    required String spaceId,
    required String userId,
    required String requesterId,
  }) async {
    try {
      // 1. リクエスト者の権限チェック
      final requesterParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: requesterId)
          .where('is_active', isEqualTo: true)
          .get();

      if (requesterParticipant.docs.isEmpty) {
        throw Exception('このスペースにアクセス権限がありません');
      }

      final requesterRole = requesterParticipant.docs.first.data()['role'];

      // 2. 削除対象の参加者を取得
      final targetParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (targetParticipant.docs.isEmpty) {
        throw Exception('削除対象のユーザーが見つかりません');
      }

      final targetRole = targetParticipant.docs.first.data()['role'];

      // 3. 権限チェック（オーナーのみが他の参加者を削除可能、自分は誰でも削除可能）
      if (userId != requesterId && requesterRole != 'owner') {
        throw Exception('他の参加者を削除する権限がありません');
      }

      // 4. オーナーは削除できない（譲渡が必要）
      if (targetRole == 'owner') {
        throw Exception('オーナーは削除できません。オーナーを譲渡してください');
      }

      // 5. 参加者を非アクティブに設定
      await _firestore
          .collection(_participantsCollection)
          .doc(targetParticipant.docs.first.id)
          .update({
        'is_active': false,
        'removed_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('参加者の削除に失敗しました: $e');
    }
  }

  /// スペースを削除（関連データも物理削除）
  Future<bool> deleteSpace({
    required String spaceId,
    required String userId,
  }) async {
    try {
      // 1. オーナー権限チェック
      final ownerParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: userId)
          .where('role', isEqualTo: 'owner')
          .where('is_active', isEqualTo: true)
          .get();

      if (ownerParticipant.docs.isEmpty) {
        throw Exception('スペースを削除する権限がありません');
      }

      // 2. 関連データを物理削除
      await _deleteSpaceRelatedData(spaceId);

      // 3. スペースと参加者を物理削除
      final batch = _firestore.batch();

      // スペースを削除
      final spaceRef = _firestore.collection(_spacesCollection).doc(spaceId);
      batch.delete(spaceRef);

      // 全ての参加者を削除
      final participants = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final participant in participants.docs) {
        batch.delete(participant.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('スペースの削除に失敗しました: $e');
    }
  }

  /// スペースに関連するデータを物理削除
  Future<void> _deleteSpaceRelatedData(String spaceId) async {
    try {
      // 1. スケジュールを削除
      final schedules = await _firestore
          .collection('schedules')
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final schedule in schedules.docs) {
        await schedule.reference.delete();
      }

      // 2. 家計簿取引を削除
      final transactions = await _firestore
          .collection('transactions')
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final transaction in transactions.docs) {
        await transaction.reference.delete();
      }

      // 3. 買い物リストグループを取得して削除
      final shoppingGroups = await _firestore
          .collection('shopping_list_groups')
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final group in shoppingGroups.docs) {
        // グループに紐づくアイテムを削除
        final items = await _firestore
            .collection('shopping_list_items')
            .where('group_id', isEqualTo: group.id)
            .get();

        for (final item in items.docs) {
          await item.reference.delete();
        }

        // グループを削除
        await group.reference.delete();
      }

      // 4. カテゴリを削除
      final categories = await _firestore
          .collection('categories')
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final category in categories.docs) {
        // サブカテゴリを削除
        final subCategories = await _firestore
            .collection('sub_categories')
            .where('parent_category_id', isEqualTo: category.id)
            .get();

        for (final subCategory in subCategories.docs) {
          await subCategory.reference.delete();
        }

        // カテゴリを削除
        await category.reference.delete();
      }

      // 5. 招待コードを削除
      final invites = await _firestore
          .collection('space_invites')
          .where('space_id', isEqualTo: spaceId)
          .get();

      for (final invite in invites.docs) {
        await invite.reference.delete();
      }
    } catch (e) {
      throw Exception('関連データの削除に失敗しました: $e');
    }
  }

  /// オーナーを譲渡
  Future<bool> transferOwnership({
    required String spaceId,
    required String currentOwnerId,
    required String newOwnerId,
  }) async {
    try {
      // 1. 現在のオーナー権限チェック
      final currentOwnerParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: currentOwnerId)
          .where('role', isEqualTo: 'owner')
          .where('is_active', isEqualTo: true)
          .get();

      if (currentOwnerParticipant.docs.isEmpty) {
        throw Exception('オーナー権限がありません');
      }

      // 2. 新しいオーナーが参加者であることを確認
      final newOwnerParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: newOwnerId)
          .where('is_active', isEqualTo: true)
          .get();

      if (newOwnerParticipant.docs.isEmpty) {
        throw Exception('新しいオーナーがスペースに参加していません');
      }

      final batch = _firestore.batch();

      // 3. スペースのオーナーIDを更新
      final spaceRef = _firestore.collection(_spacesCollection).doc(spaceId);
      batch.update(spaceRef, {
        'owner_id': newOwnerId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. 現在のオーナーをメンバーに変更
      batch.update(currentOwnerParticipant.docs.first.reference, {
        'role': 'member',
      });

      // 5. 新しいオーナーの権限を更新
      batch.update(newOwnerParticipant.docs.first.reference, {
        'role': 'owner',
      });

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('オーナー譲渡に失敗しました: $e');
    }
  }

  /// スペースのヘッダー画像URLを更新
  Future<bool> updateSpaceHeaderImage(
      String spaceId, String? headerImageUrl) async {
    try {
      await _firestore.collection(_spacesCollection).doc(spaceId).update({
        'header_image_url': headerImageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('ヘッダー画像の更新に失敗しました: $e');
    }
  }

  /// スペース名を更新
  Future<bool> updateSpaceName({
    required String spaceId,
    required String newSpaceName,
    required String requesterId,
  }) async {
    try {
      // 1. リクエスト者の権限チェック（オーナーのみがスペース名を変更可能）
      final requesterParticipant = await _firestore
          .collection(_participantsCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: requesterId)
          .where('role', isEqualTo: 'owner')
          .where('is_active', isEqualTo: true)
          .get();

      if (requesterParticipant.docs.isEmpty) {
        throw Exception('スペース名を変更する権限がありません（オーナーのみ変更可能）');
      }

      // 2. スペース名を更新
      await _firestore.collection(_spacesCollection).doc(spaceId).update({
        'space_name': newSpaceName,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('スペース名の更新に失敗しました: $e');
    }
  }
}
