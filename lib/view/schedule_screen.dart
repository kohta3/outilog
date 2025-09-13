import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/component/schedule/week_schadule_component.dart';
import 'package:outi_log/view/component/schedule/dialog_component.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleFirestoreProvider.notifier).reloadSchedules();
    });
  }

  // getSchedulesForDayをbuildメソッドの外に移動
  List<ScheduleModel> _getSchedulesForDay(DateTime day) {
    final scheduleNotifier = ref.read(scheduleFirestoreProvider.notifier);
    return scheduleNotifier.getSchedulesForDate(day);
  }

  @override
  Widget build(BuildContext context) {
    // スケジュールの状態を監視
    final schedules = ref.watch(scheduleFirestoreProvider);

    return DefaultTabController(
        length: 2,
        child: Scaffold(
            backgroundColor: background,
            body: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                  Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: TabBar(
                                  tabs: const [
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.calendar_month, size: 18),
                                          SizedBox(width: 8),
                                          Text('月'),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.view_week, size: 18),
                                          SizedBox(width: 8),
                                          Text('4日間'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  indicator: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.grey[600],
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                )),
                          ),
                          Flexible(
                            flex: 1,
                            child: Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => DialogComponent(
                                      selectedDate: _selectedDay,
                                    ),
                                  );
                                },
                                child: Text('追加'),
                              ),
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2000, 1, 1),
                            lastDay: DateTime.utc(2100, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: CalendarFormat.month,
                            shouldFillViewport: true,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            eventLoader: _getSchedulesForDay,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: false,
                              leftChevronVisible: false,
                              rightChevronVisible: false,
                              headerPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              titleTextStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333), // Colors.grey[800]
                              ),
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            locale: 'ja_JP',
                            holidayPredicate: (day) =>
                                holiday_jp.isHoliday(day),
                            daysOfWeekHeight: 30.0,
                            calendarBuilders: CalendarBuilders(
                              headerTitleBuilder: (context, date) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${date.year}年${date.month}月',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800]!,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    _DayCellContent(
                                      day: day,
                                      schedules: _getSchedulesForDay(day),
                                      dayTextColor: Colors.white,
                                      isBold: true,
                                      onEditSchedule: _editSchedule,
                                      onDeleteSchedule: _deleteSchedule,
                                    ),
                                  ],
                                );
                              },
                              todayBuilder: (context, day, focusedDay) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.orange[300]!,
                                            width: 2),
                                      ),
                                    ),
                                    _DayCellContent(
                                      day: day,
                                      schedules: _getSchedulesForDay(day),
                                      dayTextColor: _getTextColorForDay(day),
                                      isBold: true,
                                      onEditSchedule: _editSchedule,
                                      onDeleteSchedule: _deleteSchedule,
                                    ),
                                  ],
                                );
                              },
                              defaultBuilder: (context, day, focusedDay) {
                                return _DayCellContent(
                                  day: day,
                                  schedules: _getSchedulesForDay(day),
                                  dayTextColor: _getTextColorForDay(day),
                                  onEditSchedule: _editSchedule,
                                  onDeleteSchedule: _deleteSchedule,
                                );
                              },
                              outsideBuilder: (context, day, focusedDay) {
                                return _DayCellContent(
                                  day: day,
                                  schedules: _getSchedulesForDay(day),
                                  dayTextColor:
                                      _getTextColorForDay(day, isOutside: true),
                                  onEditSchedule: _editSchedule,
                                  onDeleteSchedule: _deleteSchedule,
                                );
                              },
                              holidayBuilder: (context, day, focusedDay) {
                                return _DayCellContent(
                                  day: day,
                                  schedules: _getSchedulesForDay(day),
                                  dayTextColor: Colors.red[600]!,
                                  isBold: true,
                                  onEditSchedule: _editSchedule,
                                  onDeleteSchedule: _deleteSchedule,
                                );
                              },
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekendStyle: TextStyle(
                                color: Colors.red[600]!,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              weekdayStyle: TextStyle(
                                color: Colors.grey[700]!,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            calendarStyle: const CalendarStyle(
                              outsideDaysVisible: true,
                              cellMargin: EdgeInsets.all(0),
                              cellPadding: EdgeInsets.all(4),
                              markersMaxCount: 0,
                            ),
                          ),
                        ),
                        WeekSchaduleComponent(
                          schedules: schedules,
                          onEditSchedule: _editSchedule,
                          onDeleteSchedule: _deleteSchedule,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  // 日付の色を決定するヘルパーメソッド
  Color _getTextColorForDay(DateTime day, {bool isOutside = false}) {
    if (isOutside) {
      if (day.weekday == DateTime.sunday) return Colors.red[300]!;
      if (day.weekday == DateTime.saturday) return Colors.blue[300]!;
      return Colors.grey[400]!;
    }
    if (holiday_jp.isHoliday(day) || day.weekday == DateTime.sunday) {
      return Colors.red[600]!;
    }
    if (day.weekday == DateTime.saturday) return Colors.blue[600]!;
    return Colors.grey[800]!;
  }

  // スケジュール編集
  void _editSchedule(ScheduleModel schedule) {
    // 現在のダイアログが開いている場合のみ閉じる
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    showDialog(
      context: context,
      builder: (context) => DialogComponent(
        selectedDate: schedule.startDateTime,
        initialSchedule: schedule,
      ),
    );
  }

  // スケジュール削除
  void _deleteSchedule(ScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定を削除'),
        content: Text('「${schedule.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && schedule.id != null) {
      final success = await ref
          .read(scheduleFirestoreProvider.notifier)
          .deleteSchedule(schedule.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予定を削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予定の削除に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// カレンダーの各日付セルのコンテンツ（日付とラベル）を表示する共通ウィジェット
class _DayCellContent extends StatelessWidget {
  final DateTime day;
  final List<ScheduleModel> schedules;
  final Color dayTextColor;
  final bool isBold;
  final Function(ScheduleModel) onEditSchedule;
  final Function(ScheduleModel) onDeleteSchedule;

  const _DayCellContent({
    required this.day,
    required this.schedules,
    required this.dayTextColor,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () async {
        await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${day.month}月${day.day}日の予定',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (schedules.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '予定はありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...schedules
                          .map((schedule) => _ScheduleListItem(
                                schedule: schedule,
                                onEdit: () => onEditSchedule(schedule),
                                onDelete: () => onDeleteSchedule(schedule),
                              ))
                          .toList(),
                    const SizedBox(height: 16),
                  ],
                )));
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: dayTextColor,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (schedules.isNotEmpty)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: schedules.take(3).map((schedule) {
                      return Flexible(
                          child: _MultiDayScheduleLabel(
                        schedule: schedule,
                        day: day, // 現在の日付を渡す
                      ));
                    }).toList(),
                  ),
                ),
              ),
            if (schedules.isEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 複数日にまたがるスケジュールラベルを表示するウィジェット (新規追加)
class _MultiDayScheduleLabel extends StatelessWidget {
  final ScheduleModel schedule;
  final DateTime day; // このラベルが表示される日付

  const _MultiDayScheduleLabel({
    required this.schedule,
    required this.day,
  });

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.blue;
    String hexColor = colorString.replaceAll('#', '');
    if (hexColor.length == 6) return Color(int.parse('FF$hexColor', radix: 16));
    if (hexColor.length == 8) return Color(int.parse(hexColor, radix: 16));
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(schedule.color);

    // 日付のみを比較するために、時刻情報をリセット
    final scheduleStart = DateTime.utc(schedule.startDateTime.year,
        schedule.startDateTime.month, schedule.startDateTime.day);
    final scheduleEnd = DateTime.utc(schedule.endDateTime.year,
        schedule.endDateTime.month, schedule.endDateTime.day);
    final currentDay = DateTime.utc(day.year, day.month, day.day);

    final isStart = isSameDay(scheduleStart, currentDay);
    final isEnd = isSameDay(scheduleEnd, currentDay);

    // 角丸の設定
    BorderRadius borderRadius;
    if (isStart && isEnd) {
      // 単独日のイベント
      borderRadius = BorderRadius.circular(4);
    } else if (isStart) {
      // 開始日
      borderRadius = const BorderRadius.horizontal(left: Radius.circular(4));
    } else if (isEnd) {
      // 終了日
      borderRadius = const BorderRadius.horizontal(right: Radius.circular(4));
    } else {
      // 中間日
      borderRadius = BorderRadius.zero;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1.5), // 垂直方向の余白を少し調整
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: borderRadius,
      ),
      child: Text(
          // タイトルは開始日または週の始まりの月曜日にのみ表示
          (isStart || day.weekday == DateTime.monday) ? schedule.title : '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip, // Ellipsisだと...が見えてしまうのでclipする
          textAlign: TextAlign.center),
    );
  }
}

/// モーダルボトムシート内でスケジュールを表示するウィジェット
class _ScheduleListItem extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleListItem({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return Colors.blue;
    String hexColor = colorString.replaceAll('#', '');
    if (hexColor.length == 6) return Color(int.parse('FF$hexColor', radix: 16));
    if (hexColor.length == 8) return Color(int.parse(hexColor, radix: 16));
    return Colors.blue;
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(schedule.color);

    return GestureDetector(
      onTap: () => _showActionMenu(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (schedule.memo != null && schedule.memo!.isNotEmpty)
                    const SizedBox(height: 4),
                  if (schedule.memo != null && schedule.memo!.isNotEmpty)
                    Text(
                      schedule.memo!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(schedule.startDateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        ' - ${_formatTime(schedule.endDateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('編集'),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除'),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                onDelete();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
}
