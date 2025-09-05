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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 終日予定セクション（Googleカレンダー風）
            if (hasAllDaySchedules)
              _buildAllDaySection(schedules.where((s) => s.isAllDay).toList()),
            // メインタイムライン
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 時間軸（Googleカレンダー風）
                    _buildGoogleStyleTimeAxis(startHour, endHour),
                    // スケジュールエリア
                    Expanded(
                      child: _buildGoogleStyleScheduleArea(
                          schedules, startHour, endHour),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Googleカレンダー風の終日予定セクション
  Widget _buildAllDaySection(List<ScheduleModel> allDaySchedules) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Text(
              '終日',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: allDaySchedules.map((schedule) {
                return _buildGoogleStyleEventChip(schedule, true);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Googleカレンダー風の時間軸
  Widget _buildGoogleStyleTimeAxis(int startHour, int endHour) {
    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          for (int hour = startHour; hour <= endHour; hour++)
            Container(
              height: 60,
              width: 50,
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
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Googleカレンダー風のスケジュールエリア
  Widget _buildGoogleStyleScheduleArea(
      List<ScheduleModel> schedules, int startHour, int endHour) {
    final totalHours = endHour - startHour + 1;
    const hourHeight = 60.0;
    final timedSchedules = schedules.where((s) => !s.isAllDay).toList();

    return Container(
      height: totalHours * hourHeight,
      child: Stack(
        children: [
          // 時間グリッド（Googleカレンダー風）
          ...List.generate(totalHours + 1, (index) {
            return Positioned(
              top: index * hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.grey[200]!,
              ),
            );
          }),
          // 予定の配置
          ...timedSchedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;
            return _buildGoogleStyleEvent(
                schedule, startHour, hourHeight, index);
          }).toList(),
        ],
      ),
    );
  }

  // Googleカレンダー風の予定表示
  Widget _buildGoogleStyleEvent(
      ScheduleModel schedule, int startHour, double hourHeight, int index) {
    final startMinutes = (schedule.startDateTime.hour - startHour) * 60 +
        schedule.startDateTime.minute;
    final endMinutes = (schedule.endDateTime.hour - startHour) * 60 +
        schedule.endDateTime.minute;

    final top = (startMinutes / 60) * hourHeight;
    final height = ((endMinutes - startMinutes) / 60) * hourHeight;

    // 重複時の横位置調整
    final leftOffset = (index % 3) * 2.0; // 最大3つまで横にずらす
    final width = 200.0 - leftOffset;

    return Positioned(
      top: top,
      left: leftOffset,
      child: GestureDetector(
        onTap: () {
          // 必要に応じてタップイベントを追加
        },
        child: Container(
          width: width,
          height: height.clamp(20.0, double.infinity),
          margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: _getScheduleColor(schedule),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getScheduleColor(schedule).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 30) ...[
                  SizedBox(height: 2),
                  Text(
                    '${DateFormat('HH:mm').format(schedule.startDateTime)} - ${DateFormat('HH:mm').format(schedule.endDateTime)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 9,
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

  // Googleカレンダー風のイベントチップ（終日予定用）
  Widget _buildGoogleStyleEventChip(ScheduleModel schedule, bool isAllDay) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScheduleColor(schedule),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getScheduleColor(schedule).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAllDay) ...[
            Icon(
              Icons.event_available,
              size: 12,
              color: Colors.white,
            ),
            SizedBox(width: 4),
          ],
          Text(
            schedule.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScheduleColor(ScheduleModel schedule) {
    if (schedule.color != null && schedule.color!.isNotEmpty) {
      return _hexToColor(schedule.color!);
    }
    // Googleカレンダー風の色パレット
    final colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFF34A853), // Google Green
      Color(0xFFEA4335), // Google Red
      Color(0xFFFBBC04), // Google Yellow
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFF9800), // Orange
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
      Color(0xFFE91E63), // Pink
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
