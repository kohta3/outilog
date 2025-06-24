import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
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
    await _secureStorageController.deleteValue(key: 'isFirstLogin');
  }
}
