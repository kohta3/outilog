import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class InviteInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // コレクション名
  static const String _invitesCollection = 'space_invites';
  static const String _inviteCodeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _inviteCodeLength = 8;

  /// 招待コードを生成
  Future<String> createInviteCode({
    required String spaceId,
    required String createdBy,
    int expirationDays = 7,
  }) async {
    try {
      // 1. ユニークな招待コードを生成
      String inviteCode;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;

      do {
        inviteCode = _generateRandomCode();

        // 既存のコードと重複していないかチェック
        final existingCode = await _firestore
            .collection(_invitesCollection)
            .where('invite_code', isEqualTo: inviteCode)
            .where('is_active', isEqualTo: true)
            .get();

        isUnique = existingCode.docs.isEmpty;
        attempts++;
      } while (!isUnique && attempts < maxAttempts);

      if (!isUnique) {
        throw Exception('ユニークな招待コードの生成に失敗しました');
      }

      // 2. 招待コードを保存
      final inviteRef = _firestore.collection(_invitesCollection).doc();
      final expirationDate = DateTime.now().add(Duration(days: expirationDays));

      await inviteRef.set({
        'id': inviteRef.id,
        'invite_code': inviteCode,
        'space_id': spaceId,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(expirationDate),
        'is_active': true,
        'use_count': 0,
        'max_uses': 50, // 最大使用回数
      });

      return inviteCode;
    } catch (e) {
      throw Exception('招待コードの作成に失敗しました: $e');
    }
  }

  /// 招待コードの詳細を取得
  Future<Map<String, dynamic>?> getInviteDetails(String inviteCode) async {
    try {
      final inviteQuery = await _firestore
          .collection(_invitesCollection)
          .where('invite_code', isEqualTo: inviteCode)
          .where('is_active', isEqualTo: true)
          .get();

      if (inviteQuery.docs.isEmpty) {
        return null;
      }

      final inviteData = inviteQuery.docs.first.data();

      // 有効期限チェック
      final expiresAt = inviteData['expires_at'] as Timestamp;
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        // 期限切れの招待コードを無効化
        await _firestore
            .collection(_invitesCollection)
            .doc(inviteQuery.docs.first.id)
            .update({'is_active': false});
        return null;
      }

      // 使用回数チェック
      final useCount = inviteData['use_count'] as int;
      final maxUses = inviteData['max_uses'] as int;
      if (useCount >= maxUses) {
        return null;
      }

      // スペース情報も含めて返す
      final spaceId = inviteData['space_id'] as String;
      final spaceDoc = await _firestore.collection('spaces').doc(spaceId).get();

      if (!spaceDoc.exists || spaceDoc.data()?['is_active'] != true) {
        return null;
      }

      return {
        ...inviteData,
        'space_info': spaceDoc.data(),
      };
    } catch (e) {
      throw Exception('招待コードの確認に失敗しました: $e');
    }
  }

  /// 招待コードを使用してスペースに参加
  Future<bool> joinSpaceWithInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // 1. 招待コードの詳細を取得
      final inviteDetails = await getInviteDetails(inviteCode);
      if (inviteDetails == null) {
        throw Exception('無効な招待コードです');
      }

      final spaceId = inviteDetails['space_id'] as String;

      // 2. 既に参加しているかチェック
      final existingParticipant = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (existingParticipant.docs.isNotEmpty) {
        throw Exception('既にこのスペースに参加しています');
      }

      // 3. 参加者数の上限チェック
      final spaceInfo = inviteDetails['space_info'] as Map<String, dynamic>;
      final maxParticipants = spaceInfo['max_participants'] as int;

      final currentParticipants = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (currentParticipants.docs.length >= maxParticipants) {
        throw Exception('参加者数が上限に達しています');
      }

      final batch = _firestore.batch();

      // 4. 参加者を追加
      final participantRef = _firestore.collection('space_participants').doc();
      batch.set(participantRef, {
        'id': participantRef.id,
        'space_id': spaceId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'role': 'member',
        'joined_at': FieldValue.serverTimestamp(),
        'is_active': true,
        'joined_via_invite': inviteCode,
      });

      // 5. 招待コードの使用回数を更新
      final inviteQuery = await _firestore
          .collection(_invitesCollection)
          .where('invite_code', isEqualTo: inviteCode)
          .where('is_active', isEqualTo: true)
          .get();

      if (inviteQuery.docs.isNotEmpty) {
        batch.update(inviteQuery.docs.first.reference, {
          'use_count': FieldValue.increment(1),
          'last_used_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('スペースへの参加に失敗しました: $e');
    }
  }

  /// スペースの招待コード一覧を取得
  Future<List<Map<String, dynamic>>> getSpaceInviteCodes(String spaceId) async {
    try {
      final invitesQuery = await _firestore
          .collection(_invitesCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return invitesQuery.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('招待コード一覧の取得に失敗しました: $e');
    }
  }

  /// スペースの最新の有効な招待コードを取得（なければ作成）
  Future<String> getOrCreateInviteCode({
    required String spaceId,
    required String createdBy,
    int expirationDays = 7,
  }) async {
    try {
      // 既存の有効な招待コードを取得
      final existingInvites = await getSpaceInviteCodes(spaceId);

      if (existingInvites.isNotEmpty) {
        // 最新の招待コードを返す
        return existingInvites.first['invite_code'] as String;
      }

      // 有効な招待コードがない場合は新規作成
      return await createInviteCode(
        spaceId: spaceId,
        createdBy: createdBy,
        expirationDays: expirationDays,
      );
    } catch (e) {
      throw Exception('招待コードの取得・作成に失敗しました: $e');
    }
  }

  /// 招待コードを無効化
  Future<bool> deactivateInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // 1. 招待コードを取得
      final inviteQuery = await _firestore
          .collection(_invitesCollection)
          .where('invite_code', isEqualTo: inviteCode)
          .where('is_active', isEqualTo: true)
          .get();

      if (inviteQuery.docs.isEmpty) {
        throw Exception('招待コードが見つかりません');
      }

      final inviteData = inviteQuery.docs.first.data();
      final spaceId = inviteData['space_id'] as String;

      // 2. ユーザーがそのスペースのオーナーまたは招待コード作成者かチェック
      final userParticipant = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (userParticipant.docs.isEmpty) {
        throw Exception('このスペースにアクセス権限がありません');
      }

      final userRole = userParticipant.docs.first.data()['role'];
      final createdBy = inviteData['created_by'] as String;

      if (userRole != 'owner' && createdBy != userId) {
        throw Exception('この招待コードを無効化する権限がありません');
      }

      // 3. 招待コードを無効化
      await _firestore
          .collection(_invitesCollection)
          .doc(inviteQuery.docs.first.id)
          .update({
        'is_active': false,
        'deactivated_at': FieldValue.serverTimestamp(),
        'deactivated_by': userId,
      });

      return true;
    } catch (e) {
      throw Exception('招待コードの無効化に失敗しました: $e');
    }
  }

  /// ランダムな招待コードを生成
  String _generateRandomCode() {
    final random = Random();
    return List.generate(_inviteCodeLength, (index) {
      return _inviteCodeChars[random.nextInt(_inviteCodeChars.length)];
    }).join();
  }
}
