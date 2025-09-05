import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:intl/intl.dart';
import '../provider/event_provider.dart';
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/models/schedule_model.dart';

import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/component/schedule/dialog_component.dart';
import 'package:outi_log/view/component/schedule/timeline_schedule_view.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isTimelineView = false; // タイムライン表示の切り替えフラグ

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // デバッグ用：初期化時の日付をログ出力
    print('DEBUG: initState - _focusedDay: $_focusedDay');
    print('DEBUG: initState - _selectedDay: $_selectedDay');

    // イベントプロバイダーのテストデータを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 従来のイベントプロバイダーは必要に応じて初期化
      // Firestoreスケジュールも初期化
      ref.read(scheduleFirestoreProvider.notifier).reloadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Firestoreスケジュールを監視して状態変更を検知
    final schedules = ref.watch(scheduleFirestoreProvider);

    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => DialogComponent(
              selectedDate: _selectedDay ?? _focusedDay,
            ),
          );
        },
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          provider.Consumer<EventNotifier>(
            builder: (context, eventNotifier, child) {
              return TableCalendar(
                key: ValueKey(schedules.length), // データ変更時に再構築
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

                    // デバッグ用：日付選択時のログ出力
                    print('DEBUG: Day selected - selectedDay: $selectedDay');
                    print(
                        'DEBUG: Day selected - _selectedDay updated to: $_selectedDay');
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
                  // schedulesの変更を参照することで自動更新をトリガー
                  final _ = schedules; // 依存関係を作成

                  // Firestoreスケジュールと従来のイベントを統合
                  final firestoreEvents = ref
                      .read(scheduleFirestoreProvider.notifier)
                      .getSchedulesForDate(day);
                  final localEvents = eventNotifier.getEventsForDay(day);

                  // Firestoreスケジュールを優先し、ローカルイベントも表示
                  final allEvents = <dynamic>[];
                  allEvents.addAll(firestoreEvents);
                  allEvents.addAll(localEvents);

                  return allEvents;
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
                  // 土曜日と予定がある日の日付を強調表示
                  defaultBuilder: (context, day, focusedDay) {
                    // 土曜日の場合は青文字
                    if (day.weekday == DateTime.saturday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      );
                    }

                    // 予定がある日は青い背景で強調
                    final events = ref
                        .read(scheduleFirestoreProvider.notifier)
                        .getSchedulesForDate(day);
                    final localEvents = provider.Provider.of<EventNotifier>(
                            context,
                            listen: false)
                        .getEventsForDay(day);
                    final hasEvents =
                        events.isNotEmpty || localEvents.isNotEmpty;

                    if (hasEvents) {
                      return Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    return null;
                  },
                  // カスタムマーカーを表示（件数のみ）
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;

                    return Positioned(
                      bottom: 2,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${events.length}件',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
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
                  // デフォルトのマーカーを非表示にして、カスタムマーカーを使用
                  markerDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  // マーカーのサイズを調整
                  markerSize: 0,
                  // マーカーの位置を調整
                  markerMargin: EdgeInsets.zero,
                  // 日付の下にマーカー用のスペースを確保
                  cellMargin: EdgeInsets.only(bottom: 12),
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
          // 表示切り替えボタン
          _buildViewToggleButtons(),
          SizedBox(height: 8),
          Expanded(
            child: _isTimelineView ? _buildTimelineView() : _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    // 状態変更を監視（リビルドトリガー用）
    ref.watch(scheduleFirestoreProvider);
    final firestoreSchedules = ref
        .read(scheduleFirestoreProvider.notifier)
        .getSchedulesForDate(_selectedDay!);

    return provider.Consumer<EventNotifier>(
      builder: (context, eventNotifier, child) {
        final localEvents = eventNotifier.getEventsForDay(_selectedDay!);

        // Firestoreスケジュールとローカルイベントを統合
        final totalEvents = firestoreSchedules.length + localEvents.length;

        if (totalEvents == 0) {
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
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DialogComponent(
                          selectedDate: _selectedDay,
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: totalEvents,
          itemBuilder: (context, index) {
            // Firestoreスケジュールを先に表示
            if (index < firestoreSchedules.length) {
              final schedule = firestoreSchedules[index];
              return _buildFirestoreScheduleCard(schedule);
            } else {
              // ローカルイベントを表示
              final localIndex = index - firestoreSchedules.length;
              final event = localEvents[localIndex];
              return _buildLocalEventCard(event);
            }
          },
        );
      },
    );
  }

  Widget _buildFirestoreScheduleCard(schedule) {
    // 終日の場合は時刻を表示しない
    final timeDisplay = schedule.isAllDay
        ? '終日'
        : '${DateFormat('HH:mm').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}';

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScheduleColor(schedule),
          child: Icon(
            schedule.isAllDay ? Icons.event_available : Icons.event,
            color: Colors.white,
          ),
        ),
        title: Text(
          schedule.title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  schedule.isAllDay ? Icons.today : Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    color:
                        schedule.isAllDay ? Colors.blue[700] : Colors.grey[700],
                    fontWeight:
                        schedule.isAllDay ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (schedule.memo != null && schedule.memo!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                schedule.memo!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              // 編集ダイアログを表示
              showDialog(
                context: context,
                builder: (context) => DialogComponent(
                  selectedDate: _selectedDay,
                  initialSchedule: schedule,
                ),
              ).then((_) {
                // ダイアログ閉じた後にカレンダー更新
                setState(() {});
              });
            } else if (value == 'delete') {
              final confirmed = await _showDeleteConfirmDialog();
              if (confirmed && schedule.id != null) {
                final success = await ref
                    .read(scheduleFirestoreProvider.notifier)
                    .deleteSchedule(schedule.id!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('予定を削除しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // カレンダー表示を強制更新
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('予定の削除に失敗しました'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('編集'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // 編集ダイアログを表示
          showDialog(
            context: context,
            builder: (context) => DialogComponent(
              selectedDate: _selectedDay,
              initialSchedule: schedule,
            ),
          ).then((_) {
            // ダイアログ閉じた後にカレンダー更新
            setState(() {});
          });
        },
      ),
    );
  }

  // 16進数文字列をColorに変換
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // アルファ値を追加
    }
    return Color(int.parse(hex, radix: 16));
  }

  // スケジュールの色を取得
  Color _getScheduleColor(ScheduleModel schedule) {
    if (schedule.color != null) {
      return _hexToColor(schedule.color!);
    }
    // 色が設定されていない場合はタイトルのハッシュから色を生成
    final colors = [
      Color(0xFF375E97), // ダークブルー
      Color(0xFFFB6542), // オレンジレッド
      Color(0xFF3F681C), // ダークグリーン
      Color(0xFF6FB98F), // ミントグリーン
      Color(0xFFF18D9E), // ピンク
      Color(0xFF4CB5F5), // ライトブルー
      Color(0xFFF4CC70), // イエロー
      Color(0xFF8D230F), // ダークレッド
    ];
    final index = schedule.title.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildLocalEventCard(event) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.event_note,
            color: Colors.white,
          ),
        ),
        title: Text(event.title),
        subtitle: Text(event.time.toString()),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            // ローカルイベント削除処理
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('予定を削除'),
            content: Text('この予定を削除しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('削除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildViewToggleButtons() {
    // 状態変更を監視（リビルドトリガー用）
    ref.watch(scheduleFirestoreProvider);
    final firestoreSchedules = ref
        .read(scheduleFirestoreProvider.notifier)
        .getSchedulesForDate(_selectedDay!);

    // タイムライン表示可能な予定があるかチェック（終日予定も含む）
    final hasSchedulesForTimeline = firestoreSchedules.isNotEmpty;

    if (firestoreSchedules.isEmpty) {
      return SizedBox.shrink(); // 予定がない場合は非表示
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '表示形式:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isTimelineView = false;
                      });
                    },
                    icon: Icon(
                      Icons.list,
                      size: 18,
                      color: !_isTimelineView ? Colors.white : Colors.blue[700],
                    ),
                    label: Text(
                      'リスト',
                      style: TextStyle(
                        color:
                            !_isTimelineView ? Colors.white : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: !_isTimelineView
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_isTimelineView
                          ? Colors.blue[600]!
                          : Colors.blue[50]!,
                      side: BorderSide(
                        color: !_isTimelineView
                            ? Colors.blue[600]!
                            : Colors.blue[300]!,
                        width: 1.5,
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasSchedulesForTimeline
                        ? () {
                            setState(() {
                              _isTimelineView = true;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.schedule,
                      size: 18,
                      color: _isTimelineView
                          ? Colors.white
                          : hasSchedulesForTimeline
                              ? Colors.green[700]
                              : Colors.grey,
                    ),
                    label: Text(
                      'タイムライン',
                      style: TextStyle(
                        color: _isTimelineView
                            ? Colors.white
                            : hasSchedulesForTimeline
                                ? Colors.green[700]
                                : Colors.grey,
                        fontSize: 12,
                        fontWeight: _isTimelineView
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isTimelineView
                          ? Colors.green[600]!
                          : Colors.green[50]!,
                      side: BorderSide(
                        color: hasSchedulesForTimeline
                            ? (_isTimelineView
                                ? Colors.green[600]!
                                : Colors.green[300]!)
                            : Colors.grey,
                        width: 1.5,
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    // 状態変更を監視（リビルドトリガー用）
    ref.watch(scheduleFirestoreProvider);
    final firestoreSchedules = ref
        .read(scheduleFirestoreProvider.notifier)
        .getSchedulesForDate(_selectedDay!);

    if (firestoreSchedules.isEmpty) {
      return Center(
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
          ],
        ),
      );
    }

    return TimelineScheduleView(
      schedules: firestoreSchedules,
      selectedDate: _selectedDay!,
      onAddSchedule: () {
        showDialog(
          context: context,
          builder: (context) => DialogComponent(
            selectedDate: _selectedDay ?? _focusedDay,
          ),
        );
      },
    );
  }
}
