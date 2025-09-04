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
