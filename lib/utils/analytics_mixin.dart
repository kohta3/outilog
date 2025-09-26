import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:outi_log/services/analytics_service.dart';

/// 画面遷移のAnalytics追跡用Mixin
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  final AnalyticsService _analyticsService = AnalyticsService();

  /// 画面が表示された時に呼び出す
  void trackScreenView(String screenName, {String? screenClass}) {
    // デバッグ用ログ出力
    if (kDebugMode) {
      debugPrint('📊 Analytics: Screen View - $screenName (${screenClass ?? screenName})');
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    });
  }

  /// カスタムイベントを送信
  void trackEvent(String eventName, {Map<String, Object>? parameters}) {
    // デバッグ用ログ出力
    if (kDebugMode) {
      debugPrint('📊 Analytics: Event - $eventName ${parameters != null ? 'with parameters: $parameters' : ''}');
    }
    
    _analyticsService.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
}
