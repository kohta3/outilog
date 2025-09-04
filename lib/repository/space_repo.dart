import 'package:flutter/material.dart';
import 'package:outi_log/models/space_model.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final spaceRepoProvider = Provider<SpaceRepo>(
  (ref) =>
      SpaceRepo(ref.watch(flutterSecureStorageControllerProvider.notifier)),
);

class SpaceRepo {
  final FlutterSecureStorageController _secureStorageController;
  static const String _spacesKey = 'spaces';

  SpaceRepo(this._secureStorageController);

  Future<void> setSpaces(SpacesModel spaces) async {
    print('DEBUG: setSpaces called'); // デバッグログ
    try {
      await _secureStorageController.setValue(
          key: _spacesKey, value: jsonEncode(spaces.toJson()));
      print('DEBUG: setSpaces completed successfully'); // デバッグログ
    } catch (e) {
      print('DEBUG: setSpaces error = $e'); // デバッグログ
      rethrow;
    }
  }

  Future<SpacesModel?> getSpaces() async {
    final spaces = await _secureStorageController.getValue(key: _spacesKey);
    if (spaces == null) {
      debugPrint('Spaces not found');
      return null;
    }
    return SpacesModel.fromJson(jsonDecode(spaces));
  }

  Future<void> deleteSpaces() async {
    await _secureStorageController.deleteValue(key: _spacesKey);
  }

  Future<void> updateSpaces(SpacesModel spaces) async {
    await _secureStorageController.setValue(
        key: _spacesKey, value: jsonEncode(spaces.toJson()));
  }

  // デフォルトのスペースを作成
  Future<SpacesModel> createDefaultSpaces(String userId) async {
    final now = DateTime.now();
    final defaultSpace = SpaceModel(
      id: 'default_${userId}_${now.millisecondsSinceEpoch}',
      spaceName: 'マイホーム',
      sharedUsers: [
        SharedUser(
          name: 'あなた',
          address: userId,
        ),
      ],
      ownerId: userId,
      createdAt: now,
      updatedAt: now,
    );

    final spacesModel = SpacesModel(
      spaces: {defaultSpace.id: defaultSpace},
      currentSpaceId: defaultSpace.id,
      maxSpaces: 2, // 無料版は2つまで
    );

    await setSpaces(spacesModel);
    return spacesModel;
  }

  // 新しいスペースを追加
  Future<bool> addSpace(SpaceModel newSpace, String userId) async {
    print('DEBUG: addSpace called with userId = $userId'); // デバッグログ
    final currentSpaces = await getSpaces();
    print('DEBUG: currentSpaces = ${currentSpaces?.spaces.length}'); // デバッグログ

    // スペースがない場合は最初のスペースとして作成
    if (currentSpaces == null) {
      print('DEBUG: Creating first space'); // デバッグログ
      final newSpacesModel = SpacesModel(
        spaces: {newSpace.id: newSpace},
        currentSpaceId: newSpace.id,
        maxSpaces: 2, // 無料版は2つまで
      );
      await setSpaces(newSpacesModel);
      print('DEBUG: First space created successfully'); // デバッグログ
      return true;
    }

    // 既存のスペースがある場合は制限をチェック
    print('DEBUG: Checking space limit'); // デバッグログ
    if (!currentSpaces.canCreateSpace) {
      print('DEBUG: Space limit reached'); // デバッグログ
      return false; // スペース作成上限に達している
    }

    print('DEBUG: Adding space to existing spaces'); // デバッグログ
    final updatedSpaces = Map<String, SpaceModel>.from(currentSpaces.spaces);
    updatedSpaces[newSpace.id] = newSpace;

    final newSpacesModel = SpacesModel(
      spaces: updatedSpaces,
      currentSpaceId: newSpace.id, // 新しく作成したスペースを現在のスペースに設定
      maxSpaces: currentSpaces.maxSpaces,
    );

    await setSpaces(newSpacesModel);
    print('DEBUG: Space added successfully'); // デバッグログ
    return true;
  }

  // 現在のスペースを変更
  Future<void> switchSpace(String spaceId) async {
    final currentSpaces = await getSpaces();
    if (currentSpaces == null) return;

    if (currentSpaces.spaces.containsKey(spaceId)) {
      final newSpacesModel = SpacesModel(
        spaces: currentSpaces.spaces,
        currentSpaceId: spaceId,
        maxSpaces: currentSpaces.maxSpaces,
      );
      await setSpaces(newSpacesModel);
    }
  }

  // 個別のスペースを削除
  Future<bool> deleteSpace(String spaceId, String userId) async {
    final currentSpaces = await getSpaces();
    if (currentSpaces == null) return false;

    // 削除対象のスペースが存在するかチェック
    if (!currentSpaces.spaces.containsKey(spaceId)) {
      return false;
    }

    final spaceToDelete = currentSpaces.spaces[spaceId]!;

    // オーナーのみがスペースを削除できる
    if (spaceToDelete.ownerId != userId) {
      return false;
    }

    // スペースが1つしかない場合は削除を防ぐ
    if (currentSpaces.spaces.length <= 1) {
      return false;
    }

    // スペースを削除
    final updatedSpaces = Map<String, SpaceModel>.from(currentSpaces.spaces);
    updatedSpaces.remove(spaceId);

    // 削除したスペースが現在のスペースだった場合、別のスペースを選択
    String newCurrentSpaceId = currentSpaces.currentSpaceId;
    if (currentSpaces.currentSpaceId == spaceId) {
      newCurrentSpaceId = updatedSpaces.keys.first;
    }

    final newSpacesModel = SpacesModel(
      spaces: updatedSpaces,
      currentSpaceId: newCurrentSpaceId,
      maxSpaces: currentSpaces.maxSpaces,
    );

    await setSpaces(newSpacesModel);
    return true;
  }
}
