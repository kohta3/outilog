import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RemoteNotificationService {
  static final RemoteNotificationService _instance =
      RemoteNotificationService._internal();
  factory RemoteNotificationService() => _instance;
  RemoteNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // FCMトークンのキー
  static const String _fcmTokenKey = 'fcm_token';
  static const String _userFcmTokensCollection = 'user_fcm_tokens';

  /// FCMサービスを初期化
  Future<void> initialize() async {
    try {
      // 通知権限をリクエスト
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM: 通知権限が許可されました');

        // FCMトークンを取得・保存
        await _saveFCMToken();

        // トークン更新の監視
        _messaging.onTokenRefresh.listen((token) {
          _saveFCMToken();
        });

        // フォアグラウンドメッセージの処理
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // バックグラウンドメッセージの処理
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      } else {
        print('FCM: 通知権限が拒否されました');
      }
    } catch (e) {
      print('FCM初期化エラー: $e');
    }
  }

  /// FCMトークンを取得・保存
  Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _secureStorage.write(key: _fcmTokenKey, value: token);
        print('FCM: トークンを保存しました: $token');

        // 認証済みユーザーの場合は自動的にFirestoreに保存
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await saveUserFCMToken(currentUser.uid);
        }
      }
    } catch (e) {
      print('FCMトークン保存エラー: $e');
    }
  }

  /// ユーザーのFCMトークンをFirestoreに保存
  Future<void> saveUserFCMToken(String userId) async {
    try {
      final token = await _secureStorage.read(key: _fcmTokenKey);
      if (token != null) {
        await _firestore.collection(_userFcmTokensCollection).doc(userId).set({
          'fcm_token': token,
          'updated_at': FieldValue.serverTimestamp(),
          'is_active': true,
        });
        print('FCM: ユーザートークンをFirestoreに保存しました: $userId');
      }
    } catch (e) {
      print('FCMユーザートークン保存エラー: $e');
    }
  }

  /// スペース参加ユーザー全員にスケジュール通知を送信
  Future<void> sendScheduleNotificationToSpaceMembers({
    required String spaceId,
    required String scheduleId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String notificationType,
  }) async {
    try {
      // スペースの参加者一覧を取得
      final participantsQuery = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantsQuery.docs.isEmpty) {
        print('FCM: スペースに参加者がいません');
        return;
      }

      // 参加者のFCMトークンを取得
      final List<String> fcmTokens = [];
      for (final participant in participantsQuery.docs) {
        final userId = participant.data()['user_id'] as String;
        final tokenDoc = await _firestore
            .collection(_userFcmTokensCollection)
            .doc(userId)
            .get();

        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          if (tokenData['is_active'] == true) {
            fcmTokens.add(tokenData['fcm_token'] as String);
          }
        }
      }

      if (fcmTokens.isEmpty) {
        print('FCM: 有効なFCMトークンが見つかりません');
        return;
      }

      // 通知データを準備
      final notificationData = {
        'title': title,
        'body': body,
        'data': {
          'type': 'schedule_notification',
          'schedule_id': scheduleId,
          'space_id': spaceId,
          'notification_type': notificationType,
          'scheduled_time': scheduledTime.toIso8601String(),
        },
      };

      // 各ユーザーに通知を送信
      for (final token in fcmTokens) {
        await _sendNotificationToToken(token, notificationData);
      }

      print('FCM: ${fcmTokens.length}人のユーザーに通知を送信しました');
    } catch (e) {
      print('FCM: スペース通知送信エラー: $e');
    }
  }

  /// 特定のFCMトークンに通知を送信
  Future<void> _sendNotificationToToken(
      String token, Map<String, dynamic> notificationData) async {
    try {
      // クライアントサイドから直接FCM APIを呼び出すのは適切ではないため、
      // Firestoreに通知データを保存してサーバーサイドで処理する

      await _firestore.collection('pending_notifications').add({
        'fcm_token': token,
        'notification_data': notificationData,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'retry_count': 0,
        'target_platform': 'all', // Android/iOS両方に対応
      });

      print('FCM: 通知をキューに追加しました: $token');
      print(
          'FCM: 通知内容 - タイトル: ${notificationData['title']}, 本文: ${notificationData['body']}');
    } catch (e) {
      print('FCM: 通知送信エラー: $e');

      // エラーの場合はFirestoreに保存
      await _firestore.collection('pending_notifications').add({
        'fcm_token': token,
        'notification_data': notificationData,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'error',
        'error': e.toString(),
      });
    }
  }

  /// フォアグラウンドメッセージの処理
  void _handleForegroundMessage(RemoteMessage message) {
    print('FCM: フォアグラウンドメッセージを受信: ${message.messageId}');
    print('FCM: タイトル: ${message.notification?.title}');
    print('FCM: 本文: ${message.notification?.body}');
    print('FCM: データ: ${message.data}');

    // 必要に応じてローカル通知を表示
    // ここではログ出力のみ
  }

  /// バックグラウンドメッセージの処理
  void _handleBackgroundMessage(RemoteMessage message) {
    print('FCM: バックグラウンドメッセージを受信: ${message.messageId}');
    print('FCM: タイトル: ${message.notification?.title}');
    print('FCM: 本文: ${message.notification?.body}');
    print('FCM: データ: ${message.data}');

    // 必要に応じてアプリ内の特定画面に遷移
    // ここではログ出力のみ
  }

  /// ユーザーのFCMトークンを無効化
  Future<void> deactivateUserFCMToken(String userId) async {
    try {
      await _firestore.collection(_userFcmTokensCollection).doc(userId).update({
        'is_active': false,
        'deactivated_at': FieldValue.serverTimestamp(),
      });
      print('FCM: ユーザートークンを無効化しました: $userId');
    } catch (e) {
      print('FCM: トークン無効化エラー: $e');
    }
  }

  /// 現在のFCMトークンを取得
  Future<String?> getCurrentFCMToken() async {
    return await _secureStorage.read(key: _fcmTokenKey);
  }

  /// スケジュール作成通知をスペース参加ユーザーに送信
  Future<void> sendScheduleCreatedNotification({
    required String spaceId,
    required String scheduleId,
    required String scheduleTitle,
    required String createdByUserName,
  }) async {
    try {
      // スペースの参加者一覧を取得
      final participantsQuery = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantsQuery.docs.isEmpty) {
        print('FCM: スペースに参加者がいません');
        return;
      }

      // 参加者のFCMトークンを取得（作成者を除く）
      final List<String> fcmTokens = [];
      for (final participant in participantsQuery.docs) {
        final userId = participant.data()['user_id'] as String;
        // 作成者は除外
        if (userId == createdByUserName) continue;

        final tokenDoc = await _firestore
            .collection(_userFcmTokensCollection)
            .doc(userId)
            .get();

        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          if (tokenData['is_active'] == true) {
            fcmTokens.add(tokenData['fcm_token'] as String);
          }
        }
      }

      if (fcmTokens.isEmpty) {
        print('FCM: 有効なFCMトークンが見つかりません');
        return;
      }

      // 通知データを準備
      final notificationData = {
        'title': '新しい予定が追加されました',
        'body': '$createdByUserName さんが「$scheduleTitle」を追加しました',
        'data': {
          'type': 'schedule_created',
          'schedule_id': scheduleId,
          'space_id': spaceId,
          'created_by': createdByUserName,
        },
      };

      // 各ユーザーに通知を送信
      for (final token in fcmTokens) {
        await _sendNotificationToToken(token, notificationData);
      }

      print('FCM: ${fcmTokens.length}人のユーザーにスケジュール作成通知を送信しました');
    } catch (e) {
      print('FCM: スケジュール作成通知送信エラー: $e');
    }
  }

  /// 家計簿入力通知をスペース参加ユーザーに送信
  Future<void> sendHouseholdBudgetNotification({
    required String spaceId,
    required String transactionType, // '支出' or '収入'
    required String amount,
    required String category,
    required String createdByUserName,
  }) async {
    try {
      // スペースの参加者一覧を取得
      final participantsQuery = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantsQuery.docs.isEmpty) {
        print('FCM: スペースに参加者がいません');
        return;
      }

      // 参加者のFCMトークンを取得（作成者を除く）
      final List<String> fcmTokens = [];
      for (final participant in participantsQuery.docs) {
        final userId = participant.data()['user_id'] as String;
        // 作成者は除外
        if (userId == createdByUserName) continue;

        final tokenDoc = await _firestore
            .collection(_userFcmTokensCollection)
            .doc(userId)
            .get();

        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          if (tokenData['is_active'] == true) {
            fcmTokens.add(tokenData['fcm_token'] as String);
          }
        }
      }

      if (fcmTokens.isEmpty) {
        print('FCM: 有効なFCMトークンが見つかりません');
        return;
      }

      // 通知データを準備
      final notificationData = {
        'title': '家計簿が更新されました',
        'body':
            '$createdByUserName さんが$transactionType（$category）¥$amountを記録しました',
        'data': {
          'type': 'household_budget',
          'space_id': spaceId,
          'transaction_type': transactionType,
          'amount': amount,
          'category': category,
          'created_by': createdByUserName,
        },
      };

      // 各ユーザーに通知を送信
      for (final token in fcmTokens) {
        await _sendNotificationToToken(token, notificationData);
      }

      print('FCM: ${fcmTokens.length}人のユーザーに家計簿通知を送信しました');
    } catch (e) {
      print('FCM: 家計簿通知送信エラー: $e');
    }
  }

  /// 買い物リストグループ追加通知をスペース参加ユーザーに送信
  Future<void> sendShoppingListGroupNotification({
    required String spaceId,
    required String groupName,
    required String createdByUserName,
  }) async {
    try {
      // スペースの参加者一覧を取得
      final participantsQuery = await _firestore
          .collection('space_participants')
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .get();

      if (participantsQuery.docs.isEmpty) {
        print('FCM: スペースに参加者がいません');
        return;
      }

      // 参加者のFCMトークンを取得（作成者を除く）
      final List<String> fcmTokens = [];
      for (final participant in participantsQuery.docs) {
        final userId = participant.data()['user_id'] as String;
        // 作成者は除外
        if (userId == createdByUserName) continue;

        final tokenDoc = await _firestore
            .collection(_userFcmTokensCollection)
            .doc(userId)
            .get();

        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          if (tokenData['is_active'] == true) {
            fcmTokens.add(tokenData['fcm_token'] as String);
          }
        }
      }

      if (fcmTokens.isEmpty) {
        print('FCM: 有効なFCMトークンが見つかりません');
        return;
      }

      // 通知データを準備
      final notificationData = {
        'title': '買い物リストが更新されました',
        'body': '$createdByUserName さんが「$groupName」グループを追加しました',
        'data': {
          'type': 'shopping_list_group',
          'space_id': spaceId,
          'group_name': groupName,
          'created_by': createdByUserName,
        },
      };

      // 各ユーザーに通知を送信
      for (final token in fcmTokens) {
        await _sendNotificationToToken(token, notificationData);
      }

      print('FCM: ${fcmTokens.length}人のユーザーに買い物リスト通知を送信しました');
    } catch (e) {
      print('FCM: 買い物リスト通知送信エラー: $e');
    }
  }
}

/// バックグラウンドメッセージハンドラー（トップレベル関数として定義）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('FCM: バックグラウンドメッセージハンドラー: ${message.messageId}');
  print('FCM: タイトル: ${message.notification?.title}');
  print('FCM: 本文: ${message.notification?.body}');
  print('FCM: データ: ${message.data}');
}
