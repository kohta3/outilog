import 'package:flutter/material.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/infrastructure/space_infrastructure.dart';
import 'package:outi_log/infrastructure/invite_infrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final firestoreSpaceRepoProvider = Provider<FirestoreSpaceRepo>(
  (ref) => FirestoreSpaceRepo(
    ref.watch(flutterSecureStorageControllerProvider.notifier),
  ),
);

class FirestoreSpaceRepo {
  final FlutterSecureStorageController _secureStorageController;
  final SpaceInfrastructure _spaceInfrastructure = SpaceInfrastructure();
  final InviteInfrastructure _inviteInfrastructure = InviteInfrastructure();

  // ローカルキャッシュ用のキー
  static const String _currentSpaceKey = 'current_space_id';
  static const String _userSpacesCacheKey = 'user_spaces_cache';

  FirestoreSpaceRepo(this._secureStorageController);

  /// ユーザーのスペース一覧を取得
  Future<SpacesModel?> getSpaces(String userId) async {
    try {
      debugPrint(
          'DEBUG: FirestoreSpaceRepo.getSpaces called for user: $userId');

      // Firestoreからスペース一覧を取得
      final firestoreSpaces = await _spaceInfrastructure.getUserSpaces(userId);
      debugPrint(
          'DEBUG: Retrieved ${firestoreSpaces.length} spaces from Firestore');

      if (firestoreSpaces.isEmpty) {
        debugPrint('DEBUG: No spaces found for user');
        return null;
      }

      // SpaceModelに変換
      final Map<String, SpaceModel> spacesMap = {};
      for (final spaceData in firestoreSpaces) {
        final space = _convertFirestoreToSpaceModel(spaceData);
        spacesMap[space.id] = space;
      }

      // 現在のスペースIDを取得（ローカルストレージから）
      String? currentSpaceId = await _secureStorageController.getValue(
        key: _currentSpaceKey,
      );

      // 現在のスペースIDが無効な場合は最初のスペースを設定
      if (currentSpaceId == null || !spacesMap.containsKey(currentSpaceId)) {
        currentSpaceId = spacesMap.keys.first;
        await _secureStorageController.setValue(
          key: _currentSpaceKey,
          value: currentSpaceId,
        );
      }

      final spacesModel = SpacesModel(
        spaces: spacesMap,
        currentSpaceId: currentSpaceId,
        maxSpaces: _calculateMaxSpaces(firestoreSpaces),
      );

      // ローカルキャッシュに保存
      await _cacheSpaces(spacesModel);

      return spacesModel;
    } catch (e) {
      debugPrint('DEBUG: Error getting spaces: $e');

      // セキュリティルールエラーの場合は分かりやすいメッセージを表示
      if (e.toString().contains('permission-denied')) {
        debugPrint('DEBUG: Firestoreセキュリティルールが未設定です');
        debugPrint(
            'DEBUG: FIRESTORE_SECURITY_RULES_SETUP.md を参照してセキュリティルールを設定してください');
      }

      // エラー時はローカルキャッシュから取得を試行
      final cachedSpaces = await _getSpacesFromCache();
      if (cachedSpaces != null) {
        debugPrint('DEBUG: ローカルキャッシュからスペースを読み込みました');
        return cachedSpaces;
      }

      // キャッシュもない場合はnullを返す
      debugPrint('DEBUG: スペースデータが見つかりません');
      return null;
    }
  }

  /// 新しいスペースを作成
  Future<String?> addSpace({
    required String spaceName,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      debugPrint('DEBUG: Creating space: $spaceName for user: $userId');

      // ユーザーの現在のスペース数をチェック
      final currentSpaces = await getSpaces(userId);
      if (currentSpaces != null && !currentSpaces.canCreateSpace) {
        debugPrint('DEBUG: Space creation limit reached');
        return null;
      }

      // Firestoreにスペースを作成
      final spaceId = await _spaceInfrastructure.createSpace(
        spaceName: spaceName,
        ownerId: userId,
        ownerName: userName,
        ownerEmail: userEmail,
      );

      // 現在のスペースとして設定
      await _secureStorageController.setValue(
        key: _currentSpaceKey,
        value: spaceId,
      );

      debugPrint('DEBUG: Space created successfully with ID: $spaceId');
      return spaceId;
    } catch (e) {
      debugPrint('DEBUG: Error creating space: $e');
      return null;
    }
  }

  /// 現在のスペースを変更
  Future<void> switchSpace(String spaceId, String userId) async {
    try {
      // ユーザーがそのスペースに参加しているかチェック
      final userSpaces = await _spaceInfrastructure.getUserSpaces(userId);
      final hasAccess = userSpaces.any((space) => space['id'] == spaceId);

      if (!hasAccess) {
        throw Exception('このスペースにアクセス権限がありません');
      }

      await _secureStorageController.setValue(
        key: _currentSpaceKey,
        value: spaceId,
      );
    } catch (e) {
      debugPrint('DEBUG: Error switching space: $e');
      rethrow;
    }
  }

  /// スペースを削除
  Future<bool> deleteSpace(String spaceId, String userId) async {
    try {
      debugPrint('DEBUG: Deleting space: $spaceId by user: $userId');

      final success = await _spaceInfrastructure.deleteSpace(
        spaceId: spaceId,
        userId: userId,
      );

      if (success) {
        // 削除したスペースが現在のスペースだった場合、別のスペースに切り替え
        final currentSpaceId = await _secureStorageController.getValue(
          key: _currentSpaceKey,
        );

        if (currentSpaceId == spaceId) {
          final remainingSpaces =
              await _spaceInfrastructure.getUserSpaces(userId);
          if (remainingSpaces.isNotEmpty) {
            await _secureStorageController.setValue(
              key: _currentSpaceKey,
              value: remainingSpaces.first['id'],
            );
          } else {
            await _secureStorageController.deleteValue(key: _currentSpaceKey);
          }
        }

        // キャッシュをクリア
        await _clearSpacesCache();
      }

      return success;
    } catch (e) {
      debugPrint('DEBUG: Error deleting space: $e');
      return false;
    }
  }

  /// 招待コードでスペースに参加
  Future<bool> joinSpaceWithInviteCode({
    required String inviteCode,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      debugPrint('DEBUG: Joining space with invite code: $inviteCode');

      final success = await _inviteInfrastructure.joinSpaceWithInviteCode(
        inviteCode: inviteCode,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      if (success) {
        // キャッシュをクリア（新しいスペースが追加されたため）
        await _clearSpacesCache();
      }

      return success;
    } catch (e) {
      debugPrint('DEBUG: Error joining space: $e');
      rethrow;
    }
  }

  /// 招待コードを作成
  Future<String> createInviteCode(String spaceId, String userId) async {
    try {
      return await _inviteInfrastructure.createInviteCode(
        spaceId: spaceId,
        createdBy: userId,
      );
    } catch (e) {
      debugPrint('DEBUG: Error creating invite code: $e');
      rethrow;
    }
  }

  /// 招待コードを取得（なければ作成）
  Future<String> getOrCreateInviteCode(String spaceId, String userId) async {
    try {
      return await _inviteInfrastructure.getOrCreateInviteCode(
        spaceId: spaceId,
        createdBy: userId,
      );
    } catch (e) {
      debugPrint('DEBUG: Error getting/creating invite code: $e');
      rethrow;
    }
  }

  /// スペースの詳細情報を取得
  Future<Map<String, dynamic>?> getSpaceDetails(String spaceId) async {
    try {
      return await _spaceInfrastructure.getSpaceDetails(spaceId);
    } catch (e) {
      debugPrint('DEBUG: Error getting space details: $e');
      return null;
    }
  }

  /// スペースのヘッダー画像URLを更新
  Future<bool> updateSpaceHeaderImage(
      String spaceId, String? headerImageUrl) async {
    try {
      return await _spaceInfrastructure.updateSpaceHeaderImage(
          spaceId, headerImageUrl);
    } catch (e) {
      debugPrint('DEBUG: Error updating space header image: $e');
      return false;
    }
  }

  /// スペース名を更新
  Future<bool> updateSpaceName({
    required String spaceId,
    required String newSpaceName,
    required String requesterId,
  }) async {
    try {
      debugPrint('DEBUG: Updating space name: $spaceId to $newSpaceName');

      final success = await _spaceInfrastructure.updateSpaceName(
        spaceId: spaceId,
        newSpaceName: newSpaceName,
        requesterId: requesterId,
      );

      if (success) {
        // キャッシュをクリア（スペース情報が変更されたため）
        await _clearSpacesCache();
      }

      return success;
    } catch (e) {
      debugPrint('DEBUG: Error updating space name: $e');
      return false;
    }
  }

  /// 全てのデータを削除（ログアウト時など）
  Future<void> deleteAllData() async {
    await _secureStorageController.deleteValue(key: _currentSpaceKey);
    await _clearSpacesCache();
  }

  // === プライベートメソッド ===

  /// FirestoreのデータをSpaceModelに変換
  SpaceModel _convertFirestoreToSpaceModel(Map<String, dynamic> firestoreData) {
    // 参加者情報は別途取得する必要がある場合もあるが、
    // 基本的なスペース情報のみを使用する簡易版
    print(
        'DEBUG: _convertFirestoreToSpaceModel - header_image_url: ${firestoreData['header_image_url']}');

    return SpaceModel(
      id: firestoreData['id'],
      spaceName: firestoreData['space_name'],
      sharedUsers: [], // 必要に応じて参加者情報を取得
      ownerId: firestoreData['owner_id'],
      createdAt: firestoreData['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: firestoreData['updated_at']?.toDate() ?? DateTime.now(),
      headerImageUrl: firestoreData['header_image_url'],
    );
  }

  /// ユーザーの最大スペース数を計算
  int _calculateMaxSpaces(List<Map<String, dynamic>> spaces) {
    // 基本的には2つまで（無料版）
    // 将来的にはユーザーのプランに応じて変更
    return 2;
  }

  /// スペース情報をローカルにキャッシュ
  Future<void> _cacheSpaces(SpacesModel spaces) async {
    try {
      await _secureStorageController.setValue(
        key: _userSpacesCacheKey,
        value: jsonEncode(spaces.toJson()),
      );
    } catch (e) {
      debugPrint('DEBUG: Error caching spaces: $e');
    }
  }

  /// ローカルキャッシュからスペース情報を取得
  Future<SpacesModel?> _getSpacesFromCache() async {
    try {
      final cachedData = await _secureStorageController.getValue(
        key: _userSpacesCacheKey,
      );

      if (cachedData != null) {
        return SpacesModel.fromJson(jsonDecode(cachedData));
      }
    } catch (e) {
      debugPrint('DEBUG: Error getting spaces from cache: $e');
    }
    return null;
  }

  /// スペースキャッシュをクリア
  Future<void> _clearSpacesCache() async {
    await _secureStorageController.deleteValue(key: _userSpacesCacheKey);
  }
}
