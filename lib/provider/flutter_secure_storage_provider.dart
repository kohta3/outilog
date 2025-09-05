import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:outi_log/models/user_model.dart';

part 'flutter_secure_storage_provider.g.dart';

@riverpod
class FlutterSecureStorageController extends _$FlutterSecureStorageController {
  late final FlutterSecureStorage storage;

  @override
  void build() {
    storage = const FlutterSecureStorage();
  }

  Future<void> setValue({required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  Future<String?> getValue({required String key}) async {
    return await storage.read(key: key);
  }

  Future<Map<String, String>> getAllValue() async {
    return await storage.readAll();
  }

  Future<void> deleteValue({required String key}) async {
    await storage.delete(key: key);
  }

  Future<void> deleteAllValue() async {
    await storage.deleteAll();
  }

  // ユーザー情報のキャッシュ
  static const String _userCacheKey = 'cached_user_data';

  Future<void> cacheUserData(UserModel user) async {
    await setValue(key: _userCacheKey, value: user.toJson());
  }

  Future<UserModel?> getCachedUserData() async {
    final jsonString = await getValue(key: _userCacheKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonString);
      } catch (e) {
        // JSONパースに失敗した場合はキャッシュを削除
        await deleteValue(key: _userCacheKey);
        return null;
      }
    }
    return null;
  }

  Future<void> clearUserCache() async {
    await deleteValue(key: _userCacheKey);
  }
}
