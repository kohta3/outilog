import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/infrastructure/schedule_infrastructure.dart';

class SchedulerController {
  final ScheduleInfrastructure _scheduleInfrastructure;

  SchedulerController(this._scheduleInfrastructure);

  Future<void> addSchedule(ScheduleModel schedule) async {
    print(schedule.toJson());
    await _scheduleInfrastructure.addSchedule(schedule);
  }
}
