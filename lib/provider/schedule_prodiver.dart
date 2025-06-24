import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/repository/schedule_repo.dart';
import 'package:outi_log/provider/flutter_secure_storage_provider.dart';

final scheduleRepoProvider = Provider<ScheduleRepo>(
  (ref) =>
      ScheduleRepo(ref.watch(flutterSecureStorageControllerProvider.notifier)),
);
