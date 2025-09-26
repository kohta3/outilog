import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleFirestoreInfrastructure {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _schedulesCollection = 'schedules';

  /// スペース内のスケジュール一覧を取得
  Future<List<Map<String, dynamic>>> getSpaceSchedules(String spaceId) async {
    try {
      final query = await _firestore
          .collection(_schedulesCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .orderBy('start_time')
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('スケジュール一覧の取得に失敗しました: $e');
    }
  }

  /// 期間指定でスケジュールを取得
  Future<List<Map<String, dynamic>>> getSchedulesByDateRange({
    required String spaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _firestore
          .collection(_schedulesCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('is_active', isEqualTo: true)
          .where('start_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('start_time')
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('指定期間のスケジュール取得に失敗しました: $e');
    }
  }

  /// スケジュールを追加
  Future<String> addSchedule({
    required String spaceId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String color,
    required String createdBy,
    bool isAllDay = false,
    bool fiveMinutesBefore = false,
    bool tenMinutesBefore = false,
    bool thirtyMinutesBefore = false,
    bool oneHourBefore = false,
    bool threeHoursBefore = false,
    bool sixHoursBefore = false,
    bool twelveHoursBefore = false,
    bool oneDayBefore = false,
    Map<String, bool> participationList = const {},
    String? copyGroupId,
  }) async {
    try {
      final scheduleRef = _firestore.collection(_schedulesCollection).doc();

      await scheduleRef.set({
        'id': scheduleRef.id,
        'space_id': spaceId,
        'title': title,
        'description': description,
        'start_time': Timestamp.fromDate(startTime),
        'end_time': Timestamp.fromDate(endTime),
        'color': color,
        'is_all_day': isAllDay,
        'created_by': createdBy,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': true,
        // 通知設定
        'five_minutes_before': fiveMinutesBefore,
        'ten_minutes_before': tenMinutesBefore,
        'thirty_minutes_before': thirtyMinutesBefore,
        'one_hour_before': oneHourBefore,
        'three_hours_before': threeHoursBefore,
        'six_hours_before': sixHoursBefore,
        'twelve_hours_before': twelveHoursBefore,
        'one_day_before': oneDayBefore,
        // 参加ユーザーリスト
        'participation_list': participationList,
        // コピーグループID
        'copy_group_id': copyGroupId,
      });

      return scheduleRef.id;
    } catch (e) {
      throw Exception('スケジュールの追加に失敗しました: $e');
    }
  }

  /// スケジュールを更新
  Future<bool> updateSchedule({
    required String scheduleId,
    required String spaceId,
    required String userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? color,
    bool? isAllDay,
    bool? fiveMinutesBefore,
    bool? tenMinutesBefore,
    bool? thirtyMinutesBefore,
    bool? oneHourBefore,
    bool? threeHoursBefore,
    bool? sixHoursBefore,
    bool? twelveHoursBefore,
    bool? oneDayBefore,
    Map<String, bool>? participationList,
  }) async {
    try {
      // スケジュールの存在確認と権限チェック
      final scheduleDoc = await _firestore
          .collection(_schedulesCollection)
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        throw Exception('スケジュールが見つかりません');
      }

      final scheduleData = scheduleDoc.data()!;
      if (scheduleData['space_id'] != spaceId) {
        throw Exception('このスペースのスケジュールではありません');
      }

      // 更新データを準備
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startTime != null)
        updateData['start_time'] = Timestamp.fromDate(startTime);
      if (endTime != null) updateData['end_time'] = Timestamp.fromDate(endTime);
      if (color != null) updateData['color'] = color;
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      // 通知設定
      if (fiveMinutesBefore != null)
        updateData['five_minutes_before'] = fiveMinutesBefore;
      if (tenMinutesBefore != null)
        updateData['ten_minutes_before'] = tenMinutesBefore;
      if (thirtyMinutesBefore != null)
        updateData['thirty_minutes_before'] = thirtyMinutesBefore;
      if (oneHourBefore != null) updateData['one_hour_before'] = oneHourBefore;
      if (threeHoursBefore != null)
        updateData['three_hours_before'] = threeHoursBefore;
      if (sixHoursBefore != null)
        updateData['six_hours_before'] = sixHoursBefore;
      if (twelveHoursBefore != null)
        updateData['twelve_hours_before'] = twelveHoursBefore;
      if (oneDayBefore != null) updateData['one_day_before'] = oneDayBefore;
      // 参加ユーザーリスト
      if (participationList != null)
        updateData['participation_list'] = participationList;

      await _firestore
          .collection(_schedulesCollection)
          .doc(scheduleId)
          .update(updateData);

      return true;
    } catch (e) {
      throw Exception('スケジュールの更新に失敗しました: $e');
    }
  }

  /// スケジュールを削除
  Future<bool> deleteSchedule({
    required String scheduleId,
    required String spaceId,
    required String userId,
  }) async {
    try {
      // スケジュールの存在確認と権限チェック
      final scheduleDoc = await _firestore
          .collection(_schedulesCollection)
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        throw Exception('スケジュールが見つかりません');
      }

      final scheduleData = scheduleDoc.data()!;
      if (scheduleData['space_id'] != spaceId) {
        throw Exception('このスペースのスケジュールではありません');
      }

      // 作成者または管理者のみ削除可能（今回は簡易的に誰でも削除可能）
      await _firestore.collection(_schedulesCollection).doc(scheduleId).update({
        'is_active': false,
        'deleted_at': FieldValue.serverTimestamp(),
        'deleted_by': userId,
      });

      return true;
    } catch (e) {
      throw Exception('スケジュールの削除に失敗しました: $e');
    }
  }

  /// コピーグループのスケジュールを一括削除
  Future<bool> deleteScheduleGroup({
    required String copyGroupId,
    required String spaceId,
    required String userId,
  }) async {
    try {
      // コピーグループのスケジュールを取得
      final query = await _firestore
          .collection(_schedulesCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('copy_group_id', isEqualTo: copyGroupId)
          .where('is_active', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('削除対象のスケジュールが見つかりません');
      }

      // バッチ処理で一括削除
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'is_active': false,
          'deleted_at': FieldValue.serverTimestamp(),
          'deleted_by': userId,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('スケジュールグループの削除に失敗しました: $e');
    }
  }

  /// 特定のスケジュールを取得
  Future<Map<String, dynamic>?> getSchedule(String scheduleId) async {
    try {
      final doc = await _firestore
          .collection(_schedulesCollection)
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      throw Exception('スケジュールの取得に失敗しました: $e');
    }
  }

  /// ユーザーが作成したスケジュール一覧を取得
  Future<List<Map<String, dynamic>>> getUserSchedules({
    required String spaceId,
    required String userId,
  }) async {
    try {
      final query = await _firestore
          .collection(_schedulesCollection)
          .where('space_id', isEqualTo: spaceId)
          .where('created_by', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .orderBy('start_time')
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('ユーザーのスケジュール取得に失敗しました: $e');
    }
  }
}
