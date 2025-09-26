import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/provider/auth_provider.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/format.dart';

class ScheduleCopyDialog extends ConsumerStatefulWidget {
  final ScheduleModel schedule;

  const ScheduleCopyDialog({
    super.key,
    required this.schedule,
  });

  @override
  ConsumerState<ScheduleCopyDialog> createState() => _ScheduleCopyDialogState();
}

class _ScheduleCopyDialogState extends ConsumerState<ScheduleCopyDialog> {
  CopyType _selectedCopyType = CopyType.single;
  DateTime _selectedDate = DateTime.now();
  int _repeatCount = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.schedule.startDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー部分
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.copy_all,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '予定を複製',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.schedule.title}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // コンテンツ部分
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 複製タイプ選択
                    _buildCopyTypeSelector(),
                    const SizedBox(height: 20),

                    // 日付選択（単発複製の場合）
                    if (_selectedCopyType == CopyType.single) ...[
                      _buildDateSelector(),
                      const SizedBox(height: 20),
                    ],

                    // 繰り返し回数（繰り返し複製の場合）
                    if (_selectedCopyType != CopyType.single) ...[
                      _buildRepeatCountSelector(),
                      const SizedBox(height: 20),
                    ],

                    // 説明テキスト
                    _buildDescriptionText(),
                  ],
                ),
              ),
            ),

            // ボタン部分
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeColor, themeColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _copySchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '複製',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildCopyTypeGrid(),
      ],
    );
  }

  Widget _buildCopyTypeGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children:
          CopyType.values.map((type) => _buildCopyTypeCard(type)).toList(),
    );
  }

  Widget _buildCopyTypeCard(CopyType type) {
    final isSelected = _selectedCopyType == type;
    final icon = _getCopyTypeIcon(type);
    final color = _getCopyTypeColor(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCopyType = type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  )
                : null,
            color: isSelected ? null : Colors.grey[50],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getCopyTypeLabel(type),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getCopyTypeDescription(type),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '複製先の日付',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.repeat,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '繰り返し回数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _repeatCount > 1 ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _repeatCount > 1
                        ? () {
                            setState(() {
                              _repeatCount--;
                            });
                          }
                        : null,
                    icon: const Icon(
                      Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    controller:
                        TextEditingController(text: _repeatCount.toString()),
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count > 0 && count <= 100) {
                        setState(() {
                          _repeatCount = count;
                        });
                      }
                    },
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(
                    color: _repeatCount < 100 ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _repeatCount < 100
                        ? () {
                            setState(() {
                              _repeatCount++;
                            });
                          }
                        : null,
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
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

  Widget _buildDescriptionText() {
    String description = '';
    IconData icon = Icons.info;
    Color color = Colors.blue;

    switch (_selectedCopyType) {
      case CopyType.single:
        description = '指定した日に1回複製します';
        icon = Icons.event;
        color = Colors.blue;
        break;
      case CopyType.daily:
        description = '毎日${_repeatCount}回複製します（1ヶ月間）';
        icon = Icons.today;
        color = Colors.green;
        break;
      case CopyType.weekly:
        description = '毎週同じ曜日に${_repeatCount}回複製します（1年間）';
        icon = Icons.date_range;
        color = Colors.orange;
        break;
      case CopyType.monthly:
        description = '毎月同じ日に${_repeatCount}回複製します（1年間）';
        icon = Icons.calendar_month;
        color = Colors.purple;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCopyTypeLabel(CopyType type) {
    switch (type) {
      case CopyType.single:
        return '指定した日（1回のみ）';
      case CopyType.daily:
        return '毎日（1ヶ月間）';
      case CopyType.weekly:
        return '毎週（1年間）';
      case CopyType.monthly:
        return '毎月（1年間）';
    }
  }

  String _getCopyTypeDescription(CopyType type) {
    switch (type) {
      case CopyType.single:
        return '特定の日に1回だけ複製';
      case CopyType.daily:
        return '毎日同じ時間に複製（1ヶ月間）';
      case CopyType.weekly:
        return '毎週同じ曜日の同じ時間に複製（1年間）';
      case CopyType.monthly:
        return '毎月同じ日の同じ時間に複製（1年間）';
    }
  }

  IconData _getCopyTypeIcon(CopyType type) {
    switch (type) {
      case CopyType.single:
        return Icons.event;
      case CopyType.daily:
        return Icons.today;
      case CopyType.weekly:
        return Icons.date_range;
      case CopyType.monthly:
        return Icons.calendar_month;
    }
  }

  Color _getCopyTypeColor(CopyType type) {
    switch (type) {
      case CopyType.single:
        return Colors.blue;
      case CopyType.daily:
        return Colors.green;
      case CopyType.weekly:
        return Colors.orange;
      case CopyType.monthly:
        return Colors.purple;
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _copySchedule() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentSpace = ref.read(firestoreSpacesProvider)?.currentSpace;
      final currentUser = ref.read(currentUserProvider);

      if (currentSpace == null || currentUser == null) {
        _showError('スペースまたはユーザー情報が取得できません');
        return;
      }

      final success = await _performCopy();

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予定を複製しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('予定の複製に失敗しました');
      }
    } catch (e) {
      _showError('エラーが発生しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _performCopy() async {
    final originalSchedule = widget.schedule;

    // 複製グループIDを生成（複数回複製の場合のみ）
    String? copyGroupId;
    if (_selectedCopyType != CopyType.single) {
      copyGroupId = 'copy_${DateTime.now().millisecondsSinceEpoch}';
    }

    switch (_selectedCopyType) {
      case CopyType.single:
        return await _copySingle(originalSchedule, _selectedDate);

      case CopyType.daily:
        return await _copyDaily(originalSchedule, _repeatCount, copyGroupId!);

      case CopyType.weekly:
        return await _copyWeekly(originalSchedule, _repeatCount, copyGroupId!);

      case CopyType.monthly:
        return await _copyMonthly(originalSchedule, _repeatCount, copyGroupId!);
    }
  }

  Future<bool> _copySingle(ScheduleModel original, DateTime targetDate) async {
    final scheduleNotifier = ref.read(scheduleFirestoreProvider.notifier);

    // 日付を調整
    final startTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      original.startDateTime.hour,
      original.startDateTime.minute,
    );

    final endTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      original.endDateTime.hour,
      original.endDateTime.minute,
    );

    return await scheduleNotifier.addSchedule(
      title: original.title,
      description: original.memo ?? '',
      startTime: startTime,
      endTime: endTime,
      color: original.color ?? '#3B82F6',
      isAllDay: original.isAllDay,
      fiveMinutesBefore: original.fiveMinutesBefore,
      tenMinutesBefore: original.tenMinutesBefore,
      thirtyMinutesBefore: original.thirtyMinutesBefore,
      oneHourBefore: original.oneHourBefore,
      threeHoursBefore: original.threeHoursBefore,
      sixHoursBefore: original.sixHoursBefore,
      twelveHoursBefore: original.twelveHoursBefore,
      oneDayBefore: original.oneDayBefore,
      participationList: original.participationList,
    );
  }

  Future<bool> _copyDaily(
      ScheduleModel original, int count, String copyGroupId) async {
    final scheduleNotifier = ref.read(scheduleFirestoreProvider.notifier);
    final startDate = original.startDateTime;
    bool allSuccess = true;

    for (int i = 0; i < count && i < 30; i++) {
      // 最大30日
      final targetDate = startDate.add(Duration(days: i + 1));

      final startTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.startDateTime.hour,
        original.startDateTime.minute,
      );

      final endTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.endDateTime.hour,
        original.endDateTime.minute,
      );

      final success = await scheduleNotifier.addSchedule(
        title: original.title,
        description: original.memo ?? '',
        startTime: startTime,
        endTime: endTime,
        color: original.color ?? '#3B82F6',
        isAllDay: original.isAllDay,
        fiveMinutesBefore: original.fiveMinutesBefore,
        tenMinutesBefore: original.tenMinutesBefore,
        thirtyMinutesBefore: original.thirtyMinutesBefore,
        oneHourBefore: original.oneHourBefore,
        threeHoursBefore: original.threeHoursBefore,
        sixHoursBefore: original.sixHoursBefore,
        twelveHoursBefore: original.twelveHoursBefore,
        oneDayBefore: original.oneDayBefore,
        participationList: original.participationList,
        copyGroupId: copyGroupId,
      );

      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  Future<bool> _copyWeekly(
      ScheduleModel original, int count, String copyGroupId) async {
    final scheduleNotifier = ref.read(scheduleFirestoreProvider.notifier);
    final startDate = original.startDateTime;
    bool allSuccess = true;

    for (int i = 0; i < count && i < 52; i++) {
      // 最大52週
      final targetDate = startDate.add(Duration(days: (i + 1) * 7));

      final startTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.startDateTime.hour,
        original.startDateTime.minute,
      );

      final endTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.endDateTime.hour,
        original.endDateTime.minute,
      );

      final success = await scheduleNotifier.addSchedule(
        title: original.title,
        description: original.memo ?? '',
        startTime: startTime,
        endTime: endTime,
        color: original.color ?? '#3B82F6',
        isAllDay: original.isAllDay,
        fiveMinutesBefore: original.fiveMinutesBefore,
        tenMinutesBefore: original.tenMinutesBefore,
        thirtyMinutesBefore: original.thirtyMinutesBefore,
        oneHourBefore: original.oneHourBefore,
        threeHoursBefore: original.threeHoursBefore,
        sixHoursBefore: original.sixHoursBefore,
        twelveHoursBefore: original.twelveHoursBefore,
        oneDayBefore: original.oneDayBefore,
        participationList: original.participationList,
        copyGroupId: copyGroupId,
      );

      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  Future<bool> _copyMonthly(
      ScheduleModel original, int count, String copyGroupId) async {
    final scheduleNotifier = ref.read(scheduleFirestoreProvider.notifier);
    final startDate = original.startDateTime;
    bool allSuccess = true;

    for (int i = 0; i < count && i < 12; i++) {
      // 最大12ヶ月
      final targetDate = DateTime(
        startDate.year,
        startDate.month + i + 1,
        startDate.day,
      );

      final startTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.startDateTime.hour,
        original.startDateTime.minute,
      );

      final endTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        original.endDateTime.hour,
        original.endDateTime.minute,
      );

      final success = await scheduleNotifier.addSchedule(
        title: original.title,
        description: original.memo ?? '',
        startTime: startTime,
        endTime: endTime,
        color: original.color ?? '#3B82F6',
        isAllDay: original.isAllDay,
        fiveMinutesBefore: original.fiveMinutesBefore,
        tenMinutesBefore: original.tenMinutesBefore,
        thirtyMinutesBefore: original.thirtyMinutesBefore,
        oneHourBefore: original.oneHourBefore,
        threeHoursBefore: original.threeHoursBefore,
        sixHoursBefore: original.sixHoursBefore,
        twelveHoursBefore: original.twelveHoursBefore,
        oneDayBefore: original.oneDayBefore,
        participationList: original.participationList,
        copyGroupId: copyGroupId,
      );

      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum CopyType {
  single,
  daily,
  weekly,
  monthly,
}
