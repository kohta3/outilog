import 'package:flutter/foundation.dart';

/// 遅延初期化のためのユーティリティクラス
class LazyInitializer {
  static final Map<String, dynamic> _initializedServices = {};
  static final Map<String, Future<dynamic> Function()> _initializers = {};

  /// サービスを遅延初期化として登録
  static void registerService<T>(
    String serviceName,
    Future<T> Function() initializer,
  ) {
    _initializers[serviceName] = initializer as Future<dynamic> Function();
  }

  /// サービスを初期化（初回のみ実行）
  static Future<T?> getService<T>(String serviceName) async {
    if (_initializedServices.containsKey(serviceName)) {
      return _initializedServices[serviceName] as T?;
    }

    final initializer = _initializers[serviceName];
    if (initializer == null) {
      if (kDebugMode) {
        print('Service $serviceName not registered');
      }
      return null;
    }

    try {
      final service = await initializer();
      _initializedServices[serviceName] = service;
      return service as T?;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize $serviceName: $e');
      }
      return null;
    }
  }

  /// サービスが初期化済みかチェック
  static bool isServiceInitialized(String serviceName) {
    return _initializedServices.containsKey(serviceName);
  }

  /// 特定のサービスをクリア
  static void clearService(String serviceName) {
    _initializedServices.remove(serviceName);
  }

  /// 全てのサービスをクリア
  static void clearAllServices() {
    _initializedServices.clear();
  }

  /// メモリ使用量を監視
  static void monitorMemoryUsage() {
    if (kDebugMode) {
      print(
          'LazyInitializer - Initialized services: ${_initializedServices.keys.toList()}');
      print(
          'LazyInitializer - Registered services: ${_initializers.keys.toList()}');
    }
  }
}
