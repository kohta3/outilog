import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/constant/color.dart';

class TimelineScheduleView extends StatefulWidget {
  final List<ScheduleModel> schedules;
  final DateTime selectedDate;
  final VoidCallback? onAddSchedule;

  const TimelineScheduleView({
    super.key,
    required this.schedules,
    required this.selectedDate,
    this.onAddSchedule,
  });

  @override
  State<TimelineScheduleView> createState() => _TimelineScheduleViewState();
}

class _TimelineScheduleViewState extends State<TimelineScheduleView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    size: 48,
                    color: themeColor,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '予定がありません',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '新しい予定を追加してみましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // すべての予定を時間順にソート
    final sortedSchedules = List<ScheduleModel>.from(widget.schedules);
    sortedSchedules.sort((a, b) {
      // 終日予定は先頭に、時間指定予定は時間順に
      if (a.isAllDay && !b.isAllDay) return -1;
      if (!a.isAllDay && b.isAllDay) return 1;
      return a.startDateTime.compareTo(b.startDateTime);
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildTimeline(sortedSchedules),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<ScheduleModel> schedules) {
    // 終日予定がある場合は0時-24時、時間指定予定がある場合はその範囲を基準にする
    final hasAllDaySchedules = schedules.any((schedule) => schedule.isAllDay);
    final timedSchedules =
        schedules.where((schedule) => !schedule.isAllDay).toList();

    int startHour;
    int endHour;

    if (hasAllDaySchedules) {
      // 終日予定がある場合は0時から24時まで表示
      startHour = 0;
      endHour = 24;
    } else if (timedSchedules.isNotEmpty) {
      // 時間指定予定のみの場合
      final earliestTime = timedSchedules.first.startDateTime;
      final latestTime = timedSchedules.last.endDateTime;

      startHour = earliestTime.hour;
      endHour = latestTime.hour + (latestTime.minute > 0 ? 1 : 0);

      // 最低6時間のタイムラインを確保
      if (endHour - startHour < 6) {
        final midHour = (startHour + endHour) / 2;
        startHour = (midHour - 3).clamp(0, 18).floor();
        endHour = (midHour + 3).clamp(6, 24).floor();
      }

      // 前後1時間の余裕を追加
      startHour = (startHour - 1).clamp(0, 23);
      endHour = (endHour + 1).clamp(1, 24);
    } else {
      // フォールバック（通常は起こらない）
      startHour = 0;
      endHour = 24;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 時間軸
              _buildTimeAxis(startHour, endHour),
              SizedBox(width: 20),
              // スケジュールバー
              Expanded(
                child: _buildScheduleBars(schedules, startHour, endHour),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAxis(int startHour, int endHour) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int hour = startHour; hour <= endHour; hour++)
            Container(
              height: 70,
              width: 70,
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                border: hour == startHour
                    ? null
                    : Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hour % 6 == 0
                        ? themeColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: hour % 6 == 0 ? themeColor : Colors.grey[700],
                      fontWeight:
                          hour % 6 == 0 ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleBars(
      List<ScheduleModel> schedules, int startHour, int endHour) {
    final totalHours = endHour - startHour + 1;
    const hourHeight = 70.0;

    return SizedBox(
      height: totalHours * hourHeight,
      child: Stack(
        children: [
          // 背景グリッド
          ...List.generate(totalHours + 1, (index) {
            final isMainHour = (startHour + index) % 6 == 0;
            return Positioned(
              top: index * hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: isMainHour ? 2 : 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMainHour
                        ? [
                            themeColor.withOpacity(0.3),
                            themeColor.withOpacity(0.1)
                          ]
                        : [Colors.grey[200]!, Colors.grey[100]!],
                  ),
                ),
              ),
            );
          }),
          // スケジュールバー
          ...schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              child: _buildScheduleBar(schedule, startHour, hourHeight, index),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduleBar(
      ScheduleModel schedule, int startHour, double hourHeight, int index) {
    // 開始時間と終了時間の計算
    int startMinutes;
    int endMinutes;

    if (schedule.isAllDay) {
      // 終日予定は0時から24時まで（または表示範囲の最初から最後まで）
      startMinutes = (0 - startHour) * 60;
      endMinutes = (24 - startHour) * 60;
    } else {
      // 時間指定予定
      startMinutes = (schedule.startDateTime.hour - startHour) * 60 +
          schedule.startDateTime.minute;
      endMinutes = (schedule.endDateTime.hour - startHour) * 60 +
          schedule.endDateTime.minute;
    }

    final top = (startMinutes / 60) * hourHeight;
    var height = ((endMinutes - startMinutes) / 60) * hourHeight;

    // 最小高さを50に設定（タップしやすさを考慮）
    height = height < 50 ? 50 : height;

    // 複数のスケジュールが重複する場合の横位置調整
    final leftOffset = (index % 4) * 12.0; // 最大4つまで横にずらす
    final maxWidth = 150.0;
    final width = maxWidth - leftOffset;

    return Positioned(
      top: top,
      left: leftOffset,
      child: GestureDetector(
        onTap: () {
          // 必要に応じてタップイベントを追加
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: schedule.isAllDay
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getScheduleColor(schedule).withOpacity(0.9),
                      _getScheduleColor(schedule).withOpacity(0.6),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getScheduleColor(schedule),
                      _getScheduleColor(schedule).withOpacity(0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: schedule.isAllDay
                  ? _getScheduleColor(schedule).withOpacity(0.3)
                  : _getScheduleColor(schedule).withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getScheduleColor(schedule).withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 6,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (schedule.isAllDay) ...[
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.event_available,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        schedule.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        maxLines: height > 70 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (height > 60) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schedule.isAllDay
                          ? '終日'
                          : '${DateFormat('HH:mm').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (schedule.memo != null &&
                    schedule.memo!.isNotEmpty &&
                    height > 90) ...[
                  SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        schedule.memo!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScheduleColor(ScheduleModel schedule) {
    if (schedule.color != null && schedule.color!.isNotEmpty) {
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

  Color _hexToColor(String hexColor) {
    try {
      // #を削除して16進数として解析
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      // パースに失敗した場合はデフォルト色を返す
      return Color(0xFF667eea);
    }
  }
}
