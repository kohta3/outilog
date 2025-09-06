import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/services/notification_service.dart';

/// 通知サービスのプロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 通知設定のプロバイダー
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>(
        (ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationSettingsNotifier(notificationService);
});

/// 通知設定の状態管理
class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  final NotificationService _notificationService;

  NotificationSettingsNotifier(this._notificationService)
      : super({
          'scheduleNotifications': true,
          'householdBudgetNotifications': true,
          'shoppingListNotifications': true,
        }) {
    _loadSettings();
  }

  /// 通知設定を読み込み
  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      // 新しい設定キーに移行
      final newSettings = {
        'scheduleNotifications': settings['scheduleNotifications'] ??
            settings['pushNotifications'] ??
            true,
        'householdBudgetNotifications':
            settings['householdBudgetNotifications'] ?? true,
        'shoppingListNotifications':
            settings['shoppingListNotifications'] ?? true,
      };
      state = newSettings;
    } catch (e) {
      print('通知設定の読み込みに失敗しました: $e');
    }
  }

  /// 通知設定を更新
  Future<void> updateSettings(Map<String, bool> newSettings) async {
    try {
      await _notificationService.saveNotificationSettings(newSettings);
      state = newSettings;
    } catch (e) {
      print('通知設定の更新に失敗しました: $e');
    }
  }

  /// スケジュール通知の設定を切り替え
  Future<void> toggleScheduleNotifications(bool enabled) async {
    final newSettings = Map<String, bool>.from(state);
    newSettings['scheduleNotifications'] = enabled;
    await updateSettings(newSettings);
  }

  /// 家計簿通知の設定を切り替え
  Future<void> toggleHouseholdBudgetNotifications(bool enabled) async {
    final newSettings = Map<String, bool>.from(state);
    newSettings['householdBudgetNotifications'] = enabled;
    await updateSettings(newSettings);
  }

  /// 買い物リスト通知の設定を切り替え
  Future<void> toggleShoppingListNotifications(bool enabled) async {
    final newSettings = Map<String, bool>.from(state);
    newSettings['shoppingListNotifications'] = enabled;
    await updateSettings(newSettings);
  }
}
