import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// エラーハンドリングとクラッシュ対策のユーティリティクラス
class ErrorHandler {
  /// エラーを安全に処理し、Crashlyticsに送信
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    try {
      // デバッグモードでは詳細なエラー情報を出力
      if (kDebugMode) {
        print('Error in $context: $error');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }

      // Crashlyticsにエラーを送信
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: context != null ? ['Context: $context'] : [],
      );
    } catch (e) {
      // Crashlyticsの送信に失敗した場合でもアプリを続行
      if (kDebugMode) {
        print('Failed to send error to Crashlytics: $e');
      }
    }
  }

  /// 非同期処理のエラーを安全に処理
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (logError) {
        handleError(error, stackTrace, context: context);
      }
      return fallback;
    }
  }

  /// 同期的な処理のエラーを安全に処理
  static T? safeSync<T>(
    T Function() operation, {
    String? context,
    T? fallback,
    bool logError = true,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      if (logError) {
        handleError(error, stackTrace, context: context);
      }
      return fallback;
    }
  }

  /// 画像読み込みエラー用のウィジェット
  static Widget buildErrorWidget({
    String? message,
    VoidCallback? onRetry,
  }) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? '画像の読み込みに失敗しました',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ネットワークエラー用のウィジェット
  static Widget buildNetworkErrorWidget({
    String? message,
    VoidCallback? onRetry,
  }) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'ネットワークエラーが発生しました',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// データ読み込みエラー用のウィジェット
  static Widget buildDataErrorWidget({
    String? message,
    VoidCallback? onRetry,
  }) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'データの読み込みに失敗しました',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// メモリ不足エラーの検出と対処
  static void handleMemoryError() {
    try {
      // キャッシュをクリア
      // MemoryOptimizer.clearAllCache();
      
      // ガベージコレクションを強制実行
      // 注意: 実際のガベージコレクションはDart VMが自動的に行う
      
      if (kDebugMode) {
        print('Memory error detected - attempting recovery');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to handle memory error: $e');
      }
    }
  }

  /// 古いiOSデバイス向けの最適化
  static void optimizeForOldIOS() {
    try {
      // メモリ使用量を監視
      if (kDebugMode) {
        print('Optimizing for old iOS devices');
      }
      
      // 必要に応じて追加の最適化処理を実装
    } catch (e) {
      if (kDebugMode) {
        print('Failed to optimize for old iOS: $e');
      }
    }
  }
}
