import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/infrastructure/schedule_firestore_infrastructure.dart';
import 'package:outi_log/models/schedule_model.dart';

final scheduleFirestoreRepoProvider = Provider<ScheduleFirestoreRepo>((ref) {
  return ScheduleFirestoreRepo();
});

class ScheduleFirestoreRepo {
  final ScheduleFirestoreInfrastructure _infrastructure =
      ScheduleFirestoreInfrastructure();

  /// スペース内のスケジュール一覧を取得
  Future<List<ScheduleModel>> getSpaceSchedules(String spaceId) async {
    try {
      final data = await _infrastructure.getSpaceSchedules(spaceId);
      return data.map((item) => ScheduleModel.fromFirestore(item)).toList();
    } catch (e) {
      print('DEBUG: Error getting space schedules: $e');
      return [];
    }
  }

  /// 期間指定でスケジュールを取得
  Future<List<ScheduleModel>> getSchedulesByDateRange({
    required String spaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await _infrastructure.getSchedulesByDateRange(
        spaceId: spaceId,
        startDate: startDate,
        endDate: endDate,
      );
      return data.map((item) => ScheduleModel.fromFirestore(item)).toList();
    } catch (e) {
      print('DEBUG: Error getting schedules by date range: $e');
      return [];
    }
  }

  /// スケジュールを追加
  Future<bool> addSchedule({
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
      await _infrastructure.addSchedule(
        spaceId: spaceId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        color: color,
        createdBy: createdBy,
        isAllDay: isAllDay,
      );
      return true;
    } catch (e) {
      print('DEBUG: Error adding schedule: $e');
      return false;
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
      return await _infrastructure.updateSchedule(
        scheduleId: scheduleId,
        spaceId: spaceId,
        userId: userId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        color: color,
        isAllDay: isAllDay,
      );
    } catch (e) {
      print('DEBUG: Error updating schedule: $e');
      return false;
    }
  }

  /// スケジュールを削除
  Future<bool> deleteSchedule({
    required String scheduleId,
    required String spaceId,
    required String userId,
  }) async {
    try {
      return await _infrastructure.deleteSchedule(
        scheduleId: scheduleId,
        spaceId: spaceId,
        userId: userId,
      );
    } catch (e) {
      print('DEBUG: Error deleting schedule: $e');
      return false;
    }
  }

  /// ユーザーが作成したスケジュール一覧を取得
  Future<List<ScheduleModel>> getUserSchedules({
    required String spaceId,
    required String userId,
  }) async {
    try {
      final data = await _infrastructure.getUserSchedules(
        spaceId: spaceId,
        userId: userId,
      );
      return data.map((item) => ScheduleModel.fromFirestore(item)).toList();
    } catch (e) {
      print('DEBUG: Error getting user schedules: $e');
      return [];
    }
  }
}
