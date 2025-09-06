import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/services/remote_notification_service.dart';

final remoteNotificationServiceProvider =
    Provider((ref) => RemoteNotificationService());
