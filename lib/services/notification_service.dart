import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'remote_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final RemoteNotificationService _remoteNotificationService =
      RemoteNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 通知設定のキー
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  /// 通知サービスを初期化
  Future<void> initialize() async {
    // タイムゾーンデータを初期化
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // Android初期化設定
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS初期化設定
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android用の通知チャンネルを作成
    await _createNotificationChannel();

    // リモート通知サービスを初期化
    await _remoteNotificationService.initialize();
  }

  /// Android用の通知チャンネルを作成
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'schedule_notifications',
      'スケジュール通知',
      description: 'スケジュールの予定通知',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 通知がタップされた時の処理
  void _onNotificationTapped(NotificationResponse response) {
    // 通知タップ時の処理（必要に応じて実装）
    print('通知がタップされました: ${response.payload}');
  }

  /// スケジュール通知を設定
  Future<void> scheduleNotification({
    required String scheduleId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String notificationType, // '5min', '10min', '30min', '1hour', etc.
  }) async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final canScheduleExactAlarms =
            await androidPlugin.canScheduleExactNotifications();
        if (canScheduleExactAlarms != null && !canScheduleExactAlarms) {
          print('正確な時刻通知の権限がありません。通知をスケジュールできません。');
          return;
        }
      }

      // 通知IDを生成（スケジュールID + 通知タイプのハッシュ）
      final notificationId =
          _generateNotificationId(scheduleId, notificationType);

      // 通知の詳細を設定
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'schedule_notifications',
        'スケジュール通知',
        channelDescription: 'スケジュールの予定通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 通知をスケジュール
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        payload: jsonEncode({
          'scheduleId': scheduleId,
          'type': notificationType,
        }),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // スケジュールされた通知をセキュアストレージに保存
      await _saveScheduledNotification(
          scheduleId, notificationId, notificationType, scheduledTime);

      print('通知をスケジュールしました: $title at $scheduledTime');
      print('通知ID: $notificationId, 通知タイプ: $notificationType');
      print('現在時刻: ${DateTime.now()}, スケジュール時刻: $scheduledTime');
    } catch (e) {
      print('通知のスケジュールに失敗しました: $e');
    }
  }

  /// スケジュール通知をキャンセル
  Future<void> cancelNotification(
      String scheduleId, String notificationType) async {
    try {
      final notificationId =
          _generateNotificationId(scheduleId, notificationType);
      await _notifications.cancel(notificationId);
      await _removeScheduledNotification(scheduleId, notificationType);
      print('通知をキャンセルしました: $scheduleId - $notificationType');
    } catch (e) {
      print('通知のキャンセルに失敗しました: $e');
    }
  }

  /// スケジュールの全ての通知をキャンセル
  Future<void> cancelAllNotificationsForSchedule(String scheduleId) async {
    try {
      final notificationTypes = [
        '5min',
        '10min',
        '30min',
        '1hour',
        '3hour',
        '6hour',
        '12hour',
        '1day'
      ];

      for (final type in notificationTypes) {
        await cancelNotification(scheduleId, type);
      }

      print('スケジュールの全ての通知をキャンセルしました: $scheduleId');
    } catch (e) {
      print('スケジュール通知の一括キャンセルに失敗しました: $e');
    }
  }

  /// 通知IDを生成
  int _generateNotificationId(String scheduleId, String notificationType) {
    final combined = '$scheduleId-$notificationType';
    return combined.hashCode.abs();
  }

  /// スケジュールされた通知をセキュアストレージに保存
  Future<void> _saveScheduledNotification(
    String scheduleId,
    int notificationId,
    String notificationType,
    DateTime scheduledTime,
  ) async {
    try {
      final existingData =
          await _secureStorage.read(key: _scheduledNotificationsKey);
      Map<String, dynamic> notifications = {};

      if (existingData != null) {
        notifications = jsonDecode(existingData);
      }

      if (!notifications.containsKey(scheduleId)) {
        notifications[scheduleId] = {};
      }

      notifications[scheduleId][notificationType] = {
        'notificationId': notificationId,
        'scheduledTime': scheduledTime.toIso8601String(),
      };

      await _secureStorage.write(
        key: _scheduledNotificationsKey,
        value: jsonEncode(notifications),
      );
    } catch (e) {
      print('通知情報の保存に失敗しました: $e');
    }
  }

  /// スケジュールされた通知をセキュアストレージから削除
  Future<void> _removeScheduledNotification(
      String scheduleId, String notificationType) async {
    try {
      final existingData =
          await _secureStorage.read(key: _scheduledNotificationsKey);
      if (existingData == null) return;

      Map<String, dynamic> notifications = jsonDecode(existingData);

      if (notifications.containsKey(scheduleId) &&
          notifications[scheduleId].containsKey(notificationType)) {
        notifications[scheduleId].remove(notificationType);

        // スケジュールに通知が残っていない場合はスケジュール自体を削除
        if (notifications[scheduleId].isEmpty) {
          notifications.remove(scheduleId);
        }

        await _secureStorage.write(
          key: _scheduledNotificationsKey,
          value: jsonEncode(notifications),
        );
      }
    } catch (e) {
      print('通知情報の削除に失敗しました: $e');
    }
  }

  /// 通知設定を取得
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final data = await _secureStorage.read(key: _notificationSettingsKey);
      if (data != null) {
        return Map<String, bool>.from(jsonDecode(data));
      }
    } catch (e) {
      print('通知設定の取得に失敗しました: $e');
    }

    // デフォルト設定を返す
    return {
      'scheduleNotifications': true,
      'householdBudgetNotifications': true,
      'shoppingListNotifications': true,
    };
  }

  /// 通知設定を保存
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      await _secureStorage.write(
        key: _notificationSettingsKey,
        value: jsonEncode(settings),
      );
    } catch (e) {
      print('通知設定の保存に失敗しました: $e');
    }
  }

  /// スケジュールの通知を設定（複数の通知タイプに対応）
  Future<void> scheduleNotificationsForSchedule({
    required String scheduleId,
    required String title,
    required DateTime startTime,
    required Map<String, bool> notificationSettings,
    String? spaceId, // スペースIDを追加
  }) async {
    // ユーザーの通知設定をチェック
    final userNotificationSettings = await getNotificationSettings();
    if (userNotificationSettings['scheduleNotifications'] != true) {
      print('スケジュール通知が無効になっているため、通知をスケジュールしません');
      return;
    }
    // 既存の通知をキャンセル
    await cancelAllNotificationsForSchedule(scheduleId);

    // 通知設定に基づいて通知をスケジュール
    final notificationTypes = {
      'fiveMinutesBefore': 5,
      'tenMinutesBefore': 10,
      'thirtyMinutesBefore': 30,
      'oneHourBefore': 60,
      'threeHoursBefore': 180,
      'sixHoursBefore': 360,
      'twelveHoursBefore': 720,
      'oneDayBefore': 1440,
    };

    for (final entry in notificationTypes.entries) {
      final settingKey = entry.key;
      final minutesBefore = entry.value;

      if (notificationSettings[settingKey] == true) {
        final notificationTime =
            startTime.subtract(Duration(minutes: minutesBefore));

        // 過去の時刻の場合は通知しない
        if (notificationTime.isAfter(DateTime.now())) {
          String notificationType;
          switch (minutesBefore) {
            case 5:
              notificationType = '5min';
              break;
            case 10:
              notificationType = '10min';
              break;
            case 30:
              notificationType = '30min';
              break;
            case 60:
              notificationType = '1hour';
              break;
            case 180:
              notificationType = '3hour';
              break;
            case 360:
              notificationType = '6hour';
              break;
            case 720:
              notificationType = '12hour';
              break;
            case 1440:
              notificationType = '1day';
              break;
            default:
              notificationType = 'custom';
          }

          String body;
          if (minutesBefore < 60) {
            body = '${minutesBefore}分後に「$title」が始まります';
          } else if (minutesBefore < 1440) {
            final hours = minutesBefore ~/ 60;
            body = '${hours}時間後に「$title」が始まります';
          } else {
            body = '明日「$title」が始まります';
          }

          // ローカル通知をスケジュール
          print(
              'DEBUG: 通知をスケジュール中 - ID: $scheduleId, タイプ: $notificationType, 時刻: $notificationTime');
          await scheduleNotification(
            scheduleId: scheduleId,
            title: '予定のお知らせ',
            body: body,
            scheduledTime: notificationTime,
            notificationType: notificationType,
          );

          // スペースIDが指定されている場合、スペース参加ユーザー全員にリモート通知を送信
          if (spaceId != null) {
            print(
                'DEBUG: リモート通知を送信中 - スペースID: $spaceId, スケジュールID: $scheduleId');
            await _remoteNotificationService
                .sendScheduleNotificationToSpaceMembers(
              spaceId: spaceId,
              scheduleId: scheduleId,
              title: '予定のお知らせ',
              body: body,
              scheduledTime: notificationTime,
              notificationType: notificationType,
            );
          }
        }
      }
    }
  }

  /// 全ての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _secureStorage.delete(key: _scheduledNotificationsKey);
  }

  /// 通知権限をリクエスト
  Future<bool> requestPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      return result ?? false;
    } catch (e) {
      print('通知権限のリクエストに失敗しました: $e');
      return false;
    }
  }
}
