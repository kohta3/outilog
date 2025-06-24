import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outi_log/models/schedule_model.dart';

class ScheduleInfrastructure {
  final db = FirebaseFirestore.instance;

  Future<void> addSchedule(ScheduleModel schedule) async {
    await db.collection('schedules').add(schedule.toJson());
  }
}
