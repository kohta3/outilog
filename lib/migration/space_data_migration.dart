import 'package:flutter/material.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/repository/space_repo.dart';
import 'package:outi_log/repository/firestore_space_repo.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';

/// ローカルストレージからFirestoreへのデータ移行を管理するクラス
class SpaceDataMigration {
  final SpaceRepo _localRepo;
  final FirestoreSpaceRepo _firestoreRepo;
  final FlutterSecureStorageController _secureStorage;

  static const String _migrationCompletedKey = 'space_migration_completed';

  SpaceDataMigration({
    required SpaceRepo localRepo,
    required FirestoreSpaceRepo firestoreRepo,
    required FlutterSecureStorageController secureStorage,
  })  : _localRepo = localRepo,
        _firestoreRepo = firestoreRepo,
        _secureStorage = secureStorage;

  /// 移行が必要かどうかをチェック
  Future<bool> needsMigration() async {
    try {
      // 既に移行済みかチェック
      final migrationCompleted = await _secureStorage.getValue(
        key: _migrationCompletedKey,
      );

      if (migrationCompleted == 'true') {
        return false;
      }

      // ローカルにスペースデータがあるかチェック
      final localSpaces = await _localRepo.getSpaces();
      return localSpaces != null && localSpaces.spaces.isNotEmpty;
    } catch (e) {
      debugPrint('DEBUG: Error checking migration need: $e');
      return false;
    }
  }

  /// ローカルデータをFirestoreに移行
  Future<bool> migrateToFirestore({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // ローカルのスペースデータを取得
      final localSpaces = await _localRepo.getSpaces();
      if (localSpaces == null || localSpaces.spaces.isEmpty) {
        await _markMigrationCompleted();
        return true;
      }

      // 各スペースをFirestoreに移行
      int successCount = 0;
      for (final space in localSpaces.spaces.values) {
        try {
          // オーナーのスペースのみ移行（参加者のスペースは招待コードで再参加）
          if (space.ownerId == userId) {
            await _migrateSpace(space, userName, userEmail);
            successCount++;
          }
        } catch (e) {
          debugPrint('DEBUG: Error migrating space ${space.spaceName}: $e');
        }
      }

      if (successCount > 0) {
        debugPrint('DEBUG: Successfully migrated $successCount spaces');
        await _markMigrationCompleted();
        await _cleanupLocalData();
        return true;
      } else {
        debugPrint('DEBUG: No spaces were migrated');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: Error during migration: $e');
      return false;
    }
  }

  /// 個別のスペースを移行
  Future<void> _migrateSpace(
    SpaceModel space,
    String userName,
    String userEmail,
  ) async {
    // Firestoreに新しいスペースを作成
    await _firestoreRepo.addSpace(
      spaceName: space.spaceName,
      userId: space.ownerId,
      userName: userName,
      userEmail: userEmail,
    );
  }

  /// 移行完了をマーク
  Future<void> _markMigrationCompleted() async {
    await _secureStorage.setValue(
      key: _migrationCompletedKey,
      value: 'true',
    );
  }

  /// ローカルデータをクリーンアップ
  Future<void> _cleanupLocalData() async {
    try {
      await _localRepo.deleteSpaces();
      debugPrint('DEBUG: Local space data cleaned up');
    } catch (e) {
      debugPrint('DEBUG: Error cleaning up local data: $e');
    }
  }

  /// 移行状態をリセット（開発用）
  Future<void> resetMigrationState() async {
    await _secureStorage.deleteValue(key: _migrationCompletedKey);
  }
}
