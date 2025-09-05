import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/repository/schedule_firestore_repo.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';

final scheduleFirestoreProvider =
    StateNotifierProvider<ScheduleFirestoreNotifier, List<ScheduleModel>>(
        (ref) {
  final repo = ref.watch(scheduleFirestoreRepoProvider);
  final currentSpace = ref.watch(firestoreSpacesProvider)?.currentSpace;
  final currentUser = ref.watch(currentUserProvider);
  return ScheduleFirestoreNotifier(repo, currentSpace?.id, currentUser?.uid);
});

class ScheduleFirestoreNotifier extends StateNotifier<List<ScheduleModel>> {
  final ScheduleFirestoreRepo _repo;
  final String? _spaceId;
  final String? _userId;

  ScheduleFirestoreNotifier(this._repo, this._spaceId, this._userId)
      : super([]) {
    // 初期化は外部から明示的に呼び出すように変更
    // if (_spaceId != null) {
    //   _loadSchedules();
    // }
  }

  /// スケジュール一覧を読み込み
  Future<void> _loadSchedules() async {
    if (_spaceId == null) return;

    try {
      print('DEBUG: Loading schedules for space: $_spaceId');
      final schedules = await _repo.getSpaceSchedules(_spaceId);
      print('DEBUG: Loaded ${schedules.length} schedules');
      state = schedules;
    } catch (e) {
      print('DEBUG: Error loading schedules: $e');
      state = [];
    }
  }

  /// スケジュールを追加
  Future<bool> addSchedule({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String color = '#2196F3',
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
  }) async {
    if (_spaceId == null || _userId == null) {
      print('DEBUG: Cannot add schedule - missing spaceId or userId');
      return false;
    }

    try {
      print('DEBUG: Adding schedule: $title');
      final success = await _repo.addSchedule(
        spaceId: _spaceId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        color: color,
        createdBy: _userId,
        isAllDay: isAllDay,
        fiveMinutesBefore: fiveMinutesBefore,
        tenMinutesBefore: tenMinutesBefore,
        thirtyMinutesBefore: thirtyMinutesBefore,
        oneHourBefore: oneHourBefore,
        threeHoursBefore: threeHoursBefore,
        sixHoursBefore: sixHoursBefore,
        twelveHoursBefore: twelveHoursBefore,
        oneDayBefore: oneDayBefore,
        participationList: participationList,
      );

      if (success) {
        await _loadSchedules(); // 再読み込み
        print('DEBUG: Schedule added successfully');
      }

      return success;
    } catch (e) {
      print('DEBUG: Error adding schedule: $e');
      return false;
    }
  }

  /// スケジュールを更新
  Future<bool> updateSchedule({
    required String scheduleId,
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
    if (_spaceId == null || _userId == null) return false;

    try {
      print('DEBUG: Updating schedule: $scheduleId');
      final success = await _repo.updateSchedule(
        scheduleId: scheduleId,
        spaceId: _spaceId,
        userId: _userId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        color: color,
        isAllDay: isAllDay,
        fiveMinutesBefore: fiveMinutesBefore,
        tenMinutesBefore: tenMinutesBefore,
        thirtyMinutesBefore: thirtyMinutesBefore,
        oneHourBefore: oneHourBefore,
        threeHoursBefore: threeHoursBefore,
        sixHoursBefore: sixHoursBefore,
        twelveHoursBefore: twelveHoursBefore,
        oneDayBefore: oneDayBefore,
        participationList: participationList,
      );

      if (success) {
        await _loadSchedules(); // 再読み込み
        print('DEBUG: Schedule updated successfully');
      }

      return success;
    } catch (e) {
      print('DEBUG: Error updating schedule: $e');
      return false;
    }
  }

  /// スケジュールを削除
  Future<bool> deleteSchedule(String scheduleId) async {
    if (_spaceId == null || _userId == null) return false;

    try {
      print('DEBUG: Deleting schedule: $scheduleId');
      final success = await _repo.deleteSchedule(
        scheduleId: scheduleId,
        spaceId: _spaceId,
        userId: _userId,
      );

      if (success) {
        await _loadSchedules(); // 再読み込み
        print('DEBUG: Schedule deleted successfully');
      }

      return success;
    } catch (e) {
      print('DEBUG: Error deleting schedule: $e');
      return false;
    }
  }

  /// 期間指定でスケジュールを取得
  Future<List<ScheduleModel>> getSchedulesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_spaceId == null) return [];

    try {
      return await _repo.getSchedulesByDateRange(
        spaceId: _spaceId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('DEBUG: Error getting schedules by date range: $e');
      return [];
    }
  }

  /// ユーザーが作成したスケジュールを取得
  Future<List<ScheduleModel>> getUserSchedules() async {
    if (_spaceId == null || _userId == null) return [];

    try {
      return await _repo.getUserSchedules(
        spaceId: _spaceId,
        userId: _userId,
      );
    } catch (e) {
      print('DEBUG: Error getting user schedules: $e');
      return [];
    }
  }

  /// スケジュール一覧を手動で再読み込み
  Future<void> reloadSchedules() async {
    // 現在のスペースIDとユーザーIDを再取得
    if (_spaceId != null && _userId != null) {
      await _loadSchedules();
    } else {
      print('DEBUG: Cannot reload schedules - missing spaceId or userId');
    }
  }

  /// 特定の日のスケジュールを取得（複数日にまたがる予定も含む）
  List<ScheduleModel> getSchedulesForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetDateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return state.where((schedule) {
      // 終日予定の場合
      if (schedule.isAllDay) {
        final scheduleStartDate = DateTime(
          schedule.startDateTime.year,
          schedule.startDateTime.month,
          schedule.startDateTime.day,
        );
        final scheduleEndDate = DateTime(
          schedule.endDateTime.year,
          schedule.endDateTime.month,
          schedule.endDateTime.day,
        );

        // 対象日が予定の開始日から終了日の間に含まれるかチェック
        return (targetDate.isAtSameMomentAs(scheduleStartDate) ||
                targetDate.isAfter(scheduleStartDate)) &&
            (targetDate.isAtSameMomentAs(scheduleEndDate) ||
                targetDate.isBefore(scheduleEndDate));
      } else {
        // 時間指定予定の場合
        // 対象日が予定の開始時刻から終了時刻の間に含まれるかチェック
        return schedule.startDateTime.isBefore(targetDateEnd) &&
            schedule.endDateTime.isAfter(targetDate);
      }
    }).toList();
  }

  /// 今日のスケジュールを取得
  List<ScheduleModel> get todaySchedules {
    return getSchedulesForDate(DateTime.now());
  }

  /// 今週のスケジュールを取得（複数日にまたがる予定も含む）
  List<ScheduleModel> get thisWeekSchedules {
    final now = DateTime.now();
    final startOfWeek =
        DateTime(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return state.where((schedule) {
      // 終日予定の場合
      if (schedule.isAllDay) {
        final scheduleStartDate = DateTime(
          schedule.startDateTime.year,
          schedule.startDateTime.month,
          schedule.startDateTime.day,
        );
        final scheduleEndDate = DateTime(
          schedule.endDateTime.year,
          schedule.endDateTime.month,
          schedule.endDateTime.day,
        );

        // 予定の期間が今週の期間と重なるかチェック
        return scheduleStartDate.isBefore(endOfWeek) &&
            scheduleEndDate.isAfter(startOfWeek);
      } else {
        // 時間指定予定の場合
        // 予定の期間が今週の期間と重なるかチェック
        return schedule.startDateTime.isBefore(endOfWeek) &&
            schedule.endDateTime.isAfter(startOfWeek);
      }
    }).toList();
  }

  /// スケジュールの総数
  int get totalSchedulesCount => state.length;

  /// 今日のスケジュール数
  int get todaySchedulesCount => todaySchedules.length;
}
