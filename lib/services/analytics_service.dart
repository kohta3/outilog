import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics サービス
/// デバッグ時はデータを送信しないように制御
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  /// Analytics を初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    _analytics = FirebaseAnalytics.instance;

    // デバッグ時はデータ収集を無効化
    if (kDebugMode) {
      await _analytics!.setAnalyticsCollectionEnabled(false);
      debugPrint('Firebase Analytics: デバッグモードのためデータ収集を無効化');
    } else {
      await _analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('Firebase Analytics: データ収集を有効化');
    }

    _isInitialized = true;
  }

  /// データ収集が有効かどうかを確認
  bool get isDataCollectionEnabled {
    return !kDebugMode && _isInitialized;
  }

  /// カスタムイベントを送信
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isDataCollectionEnabled) {
      debugPrint('Firebase Analytics: データ収集が無効のためイベントを送信しません - $name');
      return;
    }

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Firebase Analytics: イベント送信完了 - $name');
    } catch (e) {
      debugPrint('Firebase Analytics: イベント送信エラー - $e');
    }
  }

  /// ユーザープロパティを設定
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!isDataCollectionEnabled) {
      debugPrint('Firebase Analytics: データ収集が無効のためユーザープロパティを設定しません - $name');
      return;
    }

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('Firebase Analytics: ユーザープロパティ設定完了 - $name: $value');
    } catch (e) {
      debugPrint('Firebase Analytics: ユーザープロパティ設定エラー - $e');
    }
  }

  /// ユーザーIDを設定
  Future<void> setUserId(String? userId) async {
    if (!isDataCollectionEnabled) {
      debugPrint('Firebase Analytics: データ収集が無効のためユーザーIDを設定しません');
      return;
    }

    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('Firebase Analytics: ユーザーID設定完了 - $userId');
    } catch (e) {
      debugPrint('Firebase Analytics: ユーザーID設定エラー - $e');
    }
  }

  /// 画面遷移を記録
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      name: 'screen_view',
      parameters: {
        'firebase_screen': screenName,
        'firebase_screen_class': screenClass ?? screenName,
      },
    );
  }

  /// ログインイベントを記録
  Future<void> logLogin({required String loginMethod}) async {
    await logEvent(
      name: 'login',
      parameters: {
        'method': loginMethod,
      },
    );
  }

  /// 登録イベントを記録
  Future<void> logSignUp({required String signUpMethod}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        'method': signUpMethod,
      },
    );
  }

  /// 支出記録イベントを記録
  Future<void> logExpenseRecord({
    required double amount,
    required String category,
  }) async {
    await logEvent(
      name: 'expense_record',
      parameters: {
        'amount': amount,
        'category': category,
      },
    );
  }

  /// 収入記録イベントを記録
  Future<void> logIncomeRecord({
    required double amount,
    required String category,
  }) async {
    await logEvent(
      name: 'income_record',
      parameters: {
        'amount': amount,
        'category': category,
      },
    );
  }

  /// スケジュール作成イベントを記録
  Future<void> logScheduleCreate({
    required String eventType,
  }) async {
    await logEvent(
      name: 'schedule_create',
      parameters: {
        'event_type': eventType,
      },
    );
  }

  /// 買い物リスト作成イベントを記録
  Future<void> logShoppingListCreate({
    required int itemCount,
  }) async {
    await logEvent(
      name: 'shopping_list_create',
      parameters: {
        'item_count': itemCount,
      },
    );
  }

  /// スペース作成イベントを記録
  Future<void> logSpaceCreate() async {
    await logEvent(
      name: 'space_create',
      parameters: {},
    );
  }

  /// スペース招待イベントを記録
  Future<void> logSpaceInvite() async {
    await logEvent(
      name: 'space_invite',
      parameters: {},
    );
  }
}
