import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/repository/firestore_space_repo.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/services/initial_category_service.dart';
import 'package:outi_log/infrastructure/category_firestore_infrastructure.dart';

final firestoreSpacesProvider =
    StateNotifierProvider<FirestoreSpacesNotifier, SpacesModel?>((ref) {
  final repo = ref.watch(firestoreSpaceRepoProvider);
  final currentUser = ref.watch(currentUserProvider);
  return FirestoreSpacesNotifier(repo, currentUser?.uid);
});

class FirestoreSpacesNotifier extends StateNotifier<SpacesModel?> {
  final FirestoreSpaceRepo _repo;
  final String? _userId;

  FirestoreSpacesNotifier(this._repo, this._userId) : super(null) {
    // コンストラクタで自動初期化
    if (_userId != null) {
      _autoInitialize();
    }
  }

  /// 自動初期化（非同期）
  void _autoInitialize() {
    Future.microtask(() async {
      await initializeSpaces();
    });
  }

  /// スペースを初期化
  Future<void> initializeSpaces() async {
    if (_userId == null) return;

    try {
      final spaces = await _repo.getSpaces(_userId);
      state = spaces;
    } catch (e) {
      // エラーハンドリング
      print('DEBUG: Error initializing spaces: $e');
    }
  }

  /// 新しいスペースを追加
  Future<bool> addSpace({
    required String spaceName,
    required String userName,
    required String userEmail,
  }) async {
    if (_userId == null) return false;

    // スペース制限チェック（参加と作成を合わせて2つまで）
    if (state != null && state!.spaces.length >= 2) {
      throw Exception('スペースの参加・作成上限（2個）に達しています');
    }

    try {
      final spaceId = await _repo.addSpace(
        spaceName: spaceName,
        userId: _userId,
        userName: userName,
        userEmail: userEmail,
      );

      if (spaceId != null) {
        // 初期分類・カテゴリーを作成
        await _createInitialCategories(spaceId);

        // 状態を更新
        await initializeSpaces();

        return true;
      }

      return false;
    } catch (e) {
      print('DEBUG: Error adding space: $e');
      return false;
    }
  }

  /// 初期分類・カテゴリーを作成
  Future<void> _createInitialCategories(String spaceId) async {
    if (_userId == null) return;

    try {
      final initialCategoryService = InitialCategoryService(
        CategoryFirestoreInfrastructure(),
      );

      await initialCategoryService.createInitialCategories(
        spaceId: spaceId,
        createdBy: _userId,
      );

      print(
          'DEBUG: Initial categories created successfully for space: $spaceId');
    } catch (e) {
      print('DEBUG: Error creating initial categories: $e');
      // エラーが発生してもスペース作成は成功とする
    }
  }

  /// 現在のスペースを変更
  Future<void> switchSpace(String spaceId) async {
    if (_userId == null || state == null) return;

    try {
      await _repo.switchSpace(spaceId, _userId);

      // 状態を更新
      final updatedSpaces = SpacesModel(
        spaces: state!.spaces,
        currentSpaceId: spaceId,
        maxSpaces: state!.maxSpaces,
      );
      state = updatedSpaces;
    } catch (e) {
      print('DEBUG: Error switching space: $e');
    }
  }

  /// 個別のスペースを削除
  Future<bool> deleteSpace(String spaceId) async {
    if (_userId == null || state == null) return false;

    try {
      final success = await _repo.deleteSpace(spaceId, _userId);

      if (success) {
        // 状態を更新
        await initializeSpaces();
      }

      return success;
    } catch (e) {
      print('DEBUG: Error deleting space: $e');
      return false;
    }
  }

  /// 招待コードでスペースに参加
  Future<bool> joinSpaceWithInviteCode({
    required String inviteCode,
    required String userName,
    required String userEmail,
  }) async {
    if (_userId == null) return false;

    // スペース制限チェック（参加と作成を合わせて2つまで）
    print('DEBUG: joinSpaceWithInviteCode - state = $state');
    print(
        'DEBUG: joinSpaceWithInviteCode - state?.spaces.length = ${state?.spaces.length}');

    if (state != null && state!.spaces.length >= 2) {
      throw Exception('スペースの参加・作成上限（2個）に達しています');
    }

    try {
      final success = await _repo.joinSpaceWithInviteCode(
        inviteCode: inviteCode,
        userId: _userId,
        userName: userName,
        userEmail: userEmail,
      );

      if (success) {
        // 状態を更新
        print('DEBUG: Space joined via provider, refreshing spaces');
        await initializeSpaces();
      }

      return success;
    } catch (e) {
      print('DEBUG: Error joining space: $e');
      rethrow;
    }
  }

  /// 招待コードを作成
  Future<String> createInviteCode(String spaceId) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      return await _repo.createInviteCode(spaceId, _userId);
    } catch (e) {
      print('DEBUG: Error creating invite code: $e');
      rethrow;
    }
  }

  /// 招待コードを取得（なければ作成）
  Future<String> getOrCreateInviteCode(String spaceId) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      return await _repo.getOrCreateInviteCode(spaceId, _userId);
    } catch (e) {
      print('DEBUG: Error getting/creating invite code: $e');
      rethrow;
    }
  }

  /// スペースの詳細情報を取得
  Future<Map<String, dynamic>?> getSpaceDetails(String spaceId) async {
    try {
      return await _repo.getSpaceDetails(spaceId);
    } catch (e) {
      print('DEBUG: Error getting space details: $e');
      return null;
    }
  }

  /// スペースのヘッダー画像URLを更新
  Future<bool> updateSpaceHeaderImage(
      String spaceId, String? headerImageUrl) async {
    if (_userId == null) return false;

    try {
      final success =
          await _repo.updateSpaceHeaderImage(spaceId, headerImageUrl);

      if (success) {
        // 状態を更新
        await initializeSpaces();
      }

      return success;
    } catch (e) {
      print('DEBUG: Error updating space header image: $e');
      return false;
    }
  }

  /// スペース名を更新
  Future<bool> updateSpaceName({
    required String spaceId,
    required String newSpaceName,
  }) async {
    if (_userId == null) return false;

    try {
      final success = await _repo.updateSpaceName(
        spaceId: spaceId,
        newSpaceName: newSpaceName,
        requesterId: _userId,
      );

      if (success) {
        // 状態を更新
        await initializeSpaces();
      }

      return success;
    } catch (e) {
      print('DEBUG: Error updating space name: $e');
      return false;
    }
  }

  /// スペースを再読み込み
  Future<void> reloadSpaces() async {
    await initializeSpaces();
  }

  /// 全てのデータを削除（ログアウト時など）
  Future<void> deleteAllData() async {
    try {
      await _repo.deleteAllData();
      state = null;
    } catch (e) {
      print('DEBUG: Error deleting all data: $e');
    }
  }

  /// スペース作成可能かチェック
  bool get canCreateSpace {
    if (state == null) {
      return true; // 最初のスペースは作成可能
    }
    return state!.canCreateSpace;
  }

  /// 残りスペース数
  int get remainingSpaces {
    if (state == null) {
      return 2; // デフォルトは2つまで作成可能
    }
    return state!.remainingSpaces;
  }

  /// 現在のスペース
  SpaceModel? get currentSpace => state?.currentSpace;

  /// スペース一覧
  List<SpaceModel> get allSpaces {
    if (state == null) return [];
    return state!.spaces.values.toList();
  }

  /// ユーザーがオーナーのスペース一覧
  List<SpaceModel> get ownedSpaces {
    if (state == null || _userId == null) return [];
    return state!.spaces.values
        .where((space) => space.ownerId == _userId)
        .toList();
  }

  /// ユーザーがメンバーのスペース一覧
  List<SpaceModel> get memberSpaces {
    if (state == null || _userId == null) return [];
    return state!.spaces.values
        .where((space) => space.ownerId != _userId)
        .toList();
  }
}
