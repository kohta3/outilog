import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/view/component/schedule/schedule_copy_dialog.dart';

// モダンなデザイン要素とカラーパレット
class _UIConstants {
  static const double hourRowHeight = 70.0;
  static const double headerHeight = 60.0;
  static const double timeColumnWidth = 70.0;

  // 使用するカラー定数のみ残す
  static const Color cardBackgroundColor = Colors.white;
  static const Color gridLineColor = Color(0xFFE8ECF4);
  static const Color secondaryTextColor = Color(0xFF718096);

  // (追加) 曜日・祝日用のカラー
  static const Color saturdayColor = Colors.blueAccent;
  static const Color sundayHolidayColor = Colors.redAccent;

  // グラデーション
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
}

class WeekSchaduleComponent extends StatefulWidget {
  final List<ScheduleModel> schedules;
  final Function(ScheduleModel)? onEditSchedule;
  final Function(ScheduleModel)? onDeleteSchedule;

  const WeekSchaduleComponent({
    super.key,
    required this.schedules,
    this.onEditSchedule,
    this.onDeleteSchedule,
  });

  @override
  State<WeekSchaduleComponent> createState() => _WeekSchaduleComponentState();
}

class _WeekSchaduleComponentState extends State<WeekSchaduleComponent> {
  final DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 現在時刻にスクロール位置を調整
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final currentHour = DateTime.now().hour;
    // 現在時刻より少し前にスクロール（見やすくするため）
    final targetHour = (currentHour - 2).clamp(0, 23);
    final scrollOffset = targetHour * _UIConstants.hourRowHeight;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4日間のビューを作成（今日から開始）
    final List<DateTime> days = List.generate(
      4,
      (index) => _now.add(Duration(days: index)),
    );

    // 親コンポーネントから受け取ったスケジュールデータを使用
    final schedules = widget.schedules;

    // (修正) Containerの装飾（margin, boxShadow, borderRadius）を削除して最大化
    return Container(
      color: _UIConstants.cardBackgroundColor, // 背景色のみ設定
      child: Column(
        children: [
          // ヘッダー部分
          _buildWeekHeader(days),
          // 終日イベントセクションを分離
          _buildAllDayEventsSection(days, schedules),
          // スケジュールグリッド部分
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 時刻表示列
                  SizedBox(
                    width: _UIConstants.timeColumnWidth,
                    child: _buildTimeColumn(),
                  ),
                  // 日付列
                  Expanded(
                    child: Row(
                      children: days
                          .map((day) => _buildDayColumn(day, schedules))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 週のヘッダー部分を構築
  Widget _buildWeekHeader(List<DateTime> days) {
    return Container(
      height: _UIConstants.headerHeight,
      decoration: const BoxDecoration(
        gradient: _UIConstants.headerGradient,
      ),
      child: Row(
        children: [
          // 時刻列のヘッダー（空白）
          const SizedBox(
            width: _UIConstants.timeColumnWidth,
            child: Center(
              child: Icon(
                Icons.schedule,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          // 各日のヘッダー
          ...days.map((day) => _buildDayHeader(day)),
        ],
      ),
    );
  }

  // 終日イベントセクション
  Widget _buildAllDayEventsSection(
      List<DateTime> days, List<ScheduleModel> allSchedules) {
    const maxAllDayEvents = 3;
    const itemHeight = 22.0;
    const padding = 8.0;
    const height = (maxAllDayEvents * itemHeight) + padding;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _UIConstants.gridLineColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 時刻列に対応するエリアに「終日」ラベルを追加
          const SizedBox(
            width: _UIConstants.timeColumnWidth,
            child: Center(
              child: Text(
                '終日',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _UIConstants.secondaryTextColor,
                ),
              ),
            ),
          ),
          // 各日の終日イベント
          ...days.map((day) {
            final daySchedules = _getSchedulesForDay(day, allSchedules);
            final allDaySchedules =
                daySchedules.where((s) => s.isAllDay).toList();
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: _UIConstants.gridLineColor, width: 0.5),
                  ),
                ),
                child: Column(
                  children: allDaySchedules
                      .take(maxAllDayEvents)
                      .map((schedule) => _buildAllDayEvent(schedule))
                      .toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 日付ヘッダーを構築（土日祝の色分け対応）
  Widget _buildDayHeader(DateTime date) {
    final bool isToday = DateUtils.isSameDay(date, _now);
    final dayOfWeek = DateFormat('E', 'ja_JP').format(date);
    final dayNumber = DateFormat('d').format(date);

    // 祝日かどうかを判定
    final isHoliday = holiday_jp.isHoliday(date);

    // 曜日に応じた色を決定
    Color textColor = Colors.white;
    Color dayOfWeekColor = Colors.white70;
    if (date.weekday == DateTime.saturday) {
      textColor = _UIConstants.saturdayColor;
      dayOfWeekColor = _UIConstants.saturdayColor.withOpacity(0.8);
    } else if (date.weekday == DateTime.sunday || isHoliday) {
      textColor = _UIConstants.sundayHolidayColor;
      dayOfWeekColor = _UIConstants.sundayHolidayColor.withOpacity(0.8);
    }

    return Expanded(
      child: Container(
        height: _UIConstants.headerHeight,
        // 今日をハイライトする背景はグラデーションの上に重ねる
        decoration: isToday
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        margin: isToday ? const EdgeInsets.all(8) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayOfWeek,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isToday ? Colors.white70 : dayOfWeekColor, // 今日の場合は元の色を優先
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isToday ? Colors.white : textColor, // 今日の場合は元の色を優先
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 時刻列を構築
  Widget _buildTimeColumn() {
    return Column(
      children: [
        // 0時から23時までの時刻ラベルを生成
        for (int hour = 0; hour < 24; hour++)
          Container(
            height: _UIConstants.hourRowHeight,
            width: _UIConstants.timeColumnWidth,
            decoration: BoxDecoration(
              color:
                  _isCurrentHour(hour) ? primaryColor.withOpacity(0.05) : null,
              border: const Border(
                top: BorderSide(
                  color: _UIConstants.gridLineColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      _isCurrentHour(hour) ? FontWeight.w600 : FontWeight.w400,
                  color: _isCurrentHour(hour)
                      ? primaryColor
                      : _UIConstants.secondaryTextColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 現在時刻かどうかを判定
  bool _isCurrentHour(int hour) {
    final now = DateTime.now();
    return DateUtils.isSameDay(now, _now) && now.hour == hour;
  }

  // 日付列を構築 - Stackを使用してスケジュールを重ねて表示
  Widget _buildDayColumn(DateTime date, List<ScheduleModel> allSchedules) {
    final isToday = DateUtils.isSameDay(date, _now);
    final timedSchedules = _getSchedulesForDay(date, allSchedules)
        .where((s) => !s.isAllDay) // 終日イベントは除外
        .toList();

    return Expanded(
      child: SizedBox(
        // 高さを24時間分に固定
        height: 24 * _UIConstants.hourRowHeight,
        child: Stack(
          children: [
            // 1. 背景のグリッド線
            _buildDayGridBackground(isToday),
            // 2. スケジュールイベント
            ...timedSchedules
                .map((schedule) => _buildTimedScheduleEvent(schedule, date)),
            // 3. 現在時刻のライン (最前面に表示)
            if (isToday) _buildCurrentTimeLine(),
          ],
        ),
      ),
    );
  }

  // 背景グリッドを生成するヘルパー
  Widget _buildDayGridBackground(bool isToday) {
    return Column(
      children: List.generate(24, (hour) {
        final isCurrentHour = _isCurrentHour(hour) && isToday;
        return Container(
          height: _UIConstants.hourRowHeight,
          decoration: BoxDecoration(
            color: isCurrentHour ? primaryColor.withOpacity(0.08) : null,
            border: const Border(
              top: BorderSide(
                color: _UIConstants.gridLineColor,
                width: 0.5,
              ),
              right: BorderSide(
                color: _UIConstants.gridLineColor,
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }

  // 終日イベントを構築
  Widget _buildAllDayEvent(ScheduleModel schedule) {
    final color = _parseScheduleColor(schedule.color);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: () => _showScheduleDetails(schedule),
        child: Text(
          schedule.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 現在時刻のラインを構築
  Widget _buildCurrentTimeLine() {
    final now = DateTime.now();
    final minutesFromMidnight = now.hour * 60 + now.minute;
    final topPosition = (minutesFromMidnight / 60) * _UIConstants.hourRowHeight;

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  // 時間指定スケジュールイベントを構築
  Widget _buildTimedScheduleEvent(ScheduleModel schedule, DateTime date) {
    final color = _parseScheduleColor(schedule.color);

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final effectiveStart = schedule.startDateTime.isBefore(dayStart)
        ? dayStart
        : schedule.startDateTime;
    final effectiveEnd =
        schedule.endDateTime.isAfter(dayEnd) ? dayEnd : schedule.endDateTime;

    final startMinutesFromMidnight =
        effectiveStart.hour * 60 + effectiveStart.minute;
    final durationInMinutes = effectiveEnd.difference(effectiveStart).inMinutes;

    if (durationInMinutes <= 0) {
      return const SizedBox.shrink();
    }

    final topPosition =
        (startMinutesFromMidnight / 60) * _UIConstants.hourRowHeight;
    final height = (durationInMinutes / 60) * _UIConstants.hourRowHeight;

    final isStartOfSchedule = !schedule.startDateTime.isBefore(dayStart);

    return Positioned(
      top: topPosition,
      left: 4,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: () => _showScheduleDetails(schedule),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isStartOfSchedule)
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (height > 35 &&
                    isStartOfSchedule &&
                    schedule.memo?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      schedule.memo!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // スケジュール詳細を表示
  void _showScheduleDetails(ScheduleModel schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseScheduleColor(schedule.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schedule.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('M月d日(E) HH:mm', 'ja_JP').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (schedule.memo?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.memo!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // 編集・コピー・削除ボタン
            if (widget.onEditSchedule != null ||
                widget.onDeleteSchedule != null)
              Row(
                children: [
                  if (widget.onEditSchedule != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          widget.onEditSchedule!(schedule);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('編集'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  if (widget.onEditSchedule != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        _showCopyDialog(context, schedule);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('コピー'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  if (schedule.copyGroupId != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          _showBulkDeleteDialog(context, schedule);
                        },
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        label: const Text('一括削除'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                  if (widget.onDeleteSchedule != null) const SizedBox(width: 8),
                  if (widget.onDeleteSchedule != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          widget.onDeleteSchedule!(schedule);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('削除'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // コピーダイアログを表示
  void _showCopyDialog(BuildContext context, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleCopyDialog(
        schedule: schedule,
      ),
    );
  }

  // 一括削除ダイアログを表示
  void _showBulkDeleteDialog(BuildContext context, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ一括削除'),
        content: Text(
            '「${schedule.title}」のコピーグループ（${schedule.copyGroupId}）を一括削除しますか？\n\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bulkDeleteScheduleGroup(context, schedule.copyGroupId!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('一括削除'),
          ),
        ],
      ),
    );
  }

  // スケジュールグループを一括削除
  Future<void> _bulkDeleteScheduleGroup(
      BuildContext context, String copyGroupId) async {
    // プロバイダーを使用して一括削除を実行
    // 注意: この部分は実際のプロバイダー実装に依存します
    // ここでは簡易的な実装とします
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('一括削除機能は実装中です'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 特定の日のスケジュールを取得
  List<ScheduleModel> _getSchedulesForDay(
      DateTime date, List<ScheduleModel> allSchedules) {
    return allSchedules.where((schedule) {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      if (schedule.isAllDay) {
        return DateUtils.isSameDay(schedule.startDateTime, date);
      }
      return schedule.startDateTime.isBefore(dayEnd) &&
          schedule.endDateTime.isAfter(dayStart);
    }).toList();
  }

  // スケジュールの色を解析
  Color _parseScheduleColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return scheduleColors.first;
    }

    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      } else if (hexColor.length == 8) {
        return Color(int.parse(hexColor, radix: 16));
      }
    } catch (e) {
      // 解析に失敗した場合はデフォルト色を返す
    }
    return scheduleColors.first;
  }
}
