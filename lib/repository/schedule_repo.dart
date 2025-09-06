import 'dart:convert';
import 'package:outi_log/infrastructure/schedule_infrastructure.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';
import 'package:outi_log/models/schedule_model.dart';

class ScheduleRepo {
  final FlutterSecureStorageController _secureStorageController;

  ScheduleRepo(this._secureStorageController);

  Future<List<ScheduleInfrastructure>> getSchedules() async {
    return [];
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    // TODO: スケジュールを追加する
    await _secureStorageController.setValue(
      key: 'schedule',
      value: jsonEncode(schedule.toJson()),
    );
  }

  Future<void> updateSchedule(ScheduleInfrastructure schedule) async {
    // TODO: スケジュールを更新する
  }

  Future<void> deleteSchedule(ScheduleInfrastructure schedule) async {
    // TODO: スケジュールを削除する
  }

  Future<void> getSchedule(ScheduleInfrastructure schedule) async {
    // TODO: スケジュールを取得する
  }

  /// 認証トークンをセキュアストレージに保存する
  Future<void> saveAuthToken(String token) async {
    await _secureStorageController.setValue(
      key: 'auth_token',
      value: token,
    );
  }

  /// 認証トークンを削除する
  Future<void> deleteAuthToken() async {
    await _secureStorageController.deleteValue(key: 'auth_token');
  }
}
