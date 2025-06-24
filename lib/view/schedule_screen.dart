import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:intl/intl.dart';
import '../provider/event_provider.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/component/schedule/dialog_component.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // イベントプロバイダーのテストデータを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventNotifier>().initializeEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          Consumer<EventNotifier>(
            builder: (context, eventNotifier, child) {
              return TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                onDayLongPressed: (selectedDay, focusedDay) {
                  showDialog(
                    context: context,
                    builder: (context) => DialogComponent(
                      selectedDate: selectedDay,
                    ),
                  );
                },
                // 祝日判定
                holidayPredicate: (day) {
                  return holiday_jp.isHoliday(day);
                },
                eventLoader: (day) {
                  return eventNotifier.getEventsForDay(day);
                },
                calendarBuilders: CalendarBuilders(
                  // 曜日ヘッダーのスタイル（土日）
                  dowBuilder: (context, day) {
                    if (day.weekday == DateTime.sunday) {
                      final text = DateFormat.E('ja_JP').format(day);
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (day.weekday == DateTime.saturday) {
                      final text = DateFormat.E('ja_JP').format(day);
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      );
                    }
                    return null;
                  },
                  // 土曜日の文字色を青にする
                  defaultBuilder: (context, day, focusedDay) {
                    if (day.weekday == DateTime.saturday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  // 祝日と日曜日の文字色を赤にする
                  holidayTextStyle: const TextStyle(color: Colors.red),
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  // 祝日のマーカー（紫の丸）を非表示にする
                  holidayDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  selectedDecoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                locale: 'ja_JP',
              );
            },
          ),
          SizedBox(height: 16),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return Consumer<EventNotifier>(
      builder: (context, eventNotifier, child) {
        final events = eventNotifier.getEventsForDay(_selectedDay!);

        if (events.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '予定がありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_selectedDay!.month}月${_selectedDay!.day}日',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                ),
                title: Text(event.title),
                subtitle: Text(event.time.toString()),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ),
            );
          },
        );
      },
    );
  }
}
