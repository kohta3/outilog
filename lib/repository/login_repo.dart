import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginRepoProvider = Provider<LoginRepo>(
  (ref) =>
      LoginRepo(ref.watch(flutterSecureStorageControllerProvider.notifier)),
);

class LoginRepo {
  final FlutterSecureStorageController _secureStorageController;

  LoginRepo(this._secureStorageController);

  Future<void> setIsFirstLogin() async {
    await _secureStorageController.setValue(key: 'isFirstLogin', value: 'true');
  }

  Future<bool> getIsFirstLogin() async {
    final isFirstLogin =
        await _secureStorageController.getValue(key: 'isFirstLogin');
    return isFirstLogin == null;
  }

  Future<void> logout() async {
    // セキュアストレージの全データを削除
    await _secureStorageController.deleteAllValue();
  }

  // ユーザー情報のキャッシュ機能
  Future<void> cacheUserData(UserModel user) async {
    await _secureStorageController.cacheUserData(user);
  }

  Future<UserModel?> getCachedUserData() async {
    return await _secureStorageController.getCachedUserData();
  }

  Future<void> clearUserCache() async {
    await _secureStorageController.clearUserCache();
  }
}
