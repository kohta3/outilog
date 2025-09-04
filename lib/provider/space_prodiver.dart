import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/repository/space_repo.dart';

final spaceRepoProvider = Provider<SpaceRepo>((ref) =>
    SpaceRepo(ref.watch(flutterSecureStorageControllerProvider.notifier)));

final spacesProvider =
    StateNotifierProvider<SpacesNotifier, SpacesModel?>((ref) {
  final repo = ref.watch(spaceRepoProvider);
  return SpacesNotifier(repo);
});

class SpacesNotifier extends StateNotifier<SpacesModel?> {
  final SpaceRepo _repo;

  SpacesNotifier(this._repo) : super(null);

  /// スペースを初期化
  Future<void> initializeSpaces(String userId) async {
    // 既存のスペースを確認
    final existingSpaces = await _repo.getSpaces();

    if (existingSpaces != null) {
      // 既存のスペースがある場合は使用
      state = existingSpaces;
    }
    // スペースがない場合はstateをnullのままにする（ユーザーが明示的に作成）
  }

  /// 新しいスペースを追加
  Future<bool> addSpace(SpaceModel newSpace, String userId) async {
    print('DEBUG: SpacesNotifier.addSpace called'); // デバッグログ
    if (state == null) {
      print('DEBUG: state is null, creating first space'); // デバッグログ
    }

    final success = await _repo.addSpace(newSpace, userId);
    print('DEBUG: repo.addSpace result = $success'); // デバッグログ

    if (success) {
      // 成功した場合は状態を更新
      print('DEBUG: Updating state'); // デバッグログ
      final updatedSpaces = await _repo.getSpaces();
      print('DEBUG: updatedSpaces = ${updatedSpaces?.spaces.length}'); // デバッグログ
      if (updatedSpaces != null) {
        state = updatedSpaces;
        print('DEBUG: State updated successfully'); // デバッグログ
      }
    }
    return success;
  }

  /// 現在のスペースを変更
  Future<void> switchSpace(String spaceId) async {
    if (state == null) return;

    await _repo.switchSpace(spaceId);
    final updatedSpaces = await _repo.getSpaces();
    if (updatedSpaces != null) {
      state = updatedSpaces;
    }
  }

  /// 個別のスペースを削除
  Future<bool> deleteSpace(String spaceId, String userId) async {
    if (state == null) return false;

    final success = await _repo.deleteSpace(spaceId, userId);
    if (success) {
      final updatedSpaces = await _repo.getSpaces();
      if (updatedSpaces != null) {
        state = updatedSpaces;
      } else {
        // 全てのスペースが削除された場合
        state = null;
      }
    }
    return success;
  }

  /// スペースを削除（全て削除）
  Future<void> deleteSpaces() async {
    await _repo.deleteSpaces();
    state = null;
  }

  /// スペースを再読み込み
  Future<void> reloadSpaces() async {
    final spaces = await _repo.getSpaces();
    state = spaces;
  }

  /// スペース作成可能かチェック
  bool get canCreateSpace {
    if (state == null) {
      // スペースがない場合は最初のスペースを作成可能
      return true;
    }
    return state!.canCreateSpace;
  }

  /// 残りスペース数
  int get remainingSpaces {
    if (state == null) {
      // スペースがない場合は2つ作成可能
      return 2;
    }
    return state!.remainingSpaces;
  }

  /// 現在のスペース
  SpaceModel? get currentSpace => state?.currentSpace;
}
