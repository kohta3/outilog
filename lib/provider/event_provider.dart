import 'package:flutter/foundation.dart';
import '../models/event.dart';

class EventNotifier extends ChangeNotifier {
  Map<DateTime, List<Event>> _events = {};

  Map<DateTime, List<Event>> get events => _events;

  void initializeEvents() {
    _events = {
      DateTime.now(): [
        Event('家族会議', DateTime(2025, 6, 23, 19, 0)),
        Event('買い物', DateTime(2025, 6, 23, 15, 0)),
      ],
      DateTime.now().add(Duration(days: 1)): [
        Event('病院予約', DateTime(2025, 6, 24, 10, 0)),
      ],
      DateTime.now().add(Duration(days: 3)): [
        Event('誕生日パーティー', DateTime(2025, 6, 26, 18, 0)),
      ],
    };
    notifyListeners();
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }
}
