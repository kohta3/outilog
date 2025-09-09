import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// カスタムエラーを記録
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// カスタムログを記録
  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// ユーザーIDを設定
  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// カスタムキーを設定
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// テスト用のクラッシュを発生させる（開発時のみ使用）
  static void testCrash() {
    _crashlytics.crash();
  }

  /// テスト用のエラーを記録
  static Future<void> testError() async {
    try {
      throw Exception('This is a test error for Crashlytics');
    } catch (e, stackTrace) {
      await recordError(e, stackTrace, reason: 'Test error');
    }
  }
}
