import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/scheduler_controller.dart';
import 'package:outi_log/infrastructure/schedule_infrastructure.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/provider/schedule_firestore_provider.dart';
import 'package:outi_log/provider/firestore_space_provider.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/utils/schedule_util.dart' as schedule_util;
import 'package:outi_log/view/component/common.dart';

class DialogComponent extends ConsumerStatefulWidget {
  final DateTime? selectedDate;
  final ScheduleModel? initialSchedule;

  const DialogComponent({
    super.key,
    this.selectedDate,
    this.initialSchedule,
  });

  @override
  ConsumerState<DialogComponent> createState() => _DialogComponentState();
}

class _DialogComponentState extends ConsumerState<DialogComponent> {
  String? title;
  bool isAllDay = true;
  DateTime startDateTime = DateTime.now();
  DateTime endDateTime = DateTime.now();
  String? memo;
  Color selectedColor = defaultScheduleColor; // 選択された色を追加
  bool fiveMinutesBefore = false;
  bool tenMinutesBefore = false;
  bool thirtyMinutesBefore = false;
  bool oneHourBefore = false;
  bool threeHoursBefore = false;
  bool sixHoursBefore = false;
  bool twelveHoursBefore = false;
  bool oneDayBefore = false;
  Map<String, bool> participationList = {'user1': true, 'user2': false};

  final titleController = TextEditingController();
  final memoController = TextEditingController();
  DateTime? selectedDateTime;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();

    // 既存のスケジュールデータがある場合は初期値として設定
    if (widget.initialSchedule != null) {
      final schedule = widget.initialSchedule!;
      titleController.text = schedule.title;
      memoController.text = schedule.memo ?? '';
      startDateTime = schedule.startDateTime;
      endDateTime = schedule.endDateTime;
      isAllDay = schedule.isAllDay;
      fiveMinutesBefore = schedule.fiveMinutesBefore;
      tenMinutesBefore = schedule.tenMinutesBefore;
      thirtyMinutesBefore = schedule.thirtyMinutesBefore;
      oneHourBefore = schedule.oneHourBefore;
      threeHoursBefore = schedule.threeHoursBefore;
      sixHoursBefore = schedule.sixHoursBefore;
      twelveHoursBefore = schedule.twelveHoursBefore;
      oneDayBefore = schedule.oneDayBefore;
      participationList = Map.from(schedule.participationList);
      // 色設定は一時的に無効化
    } else {
      // 新規作成の場合、選択された日付を設定
      if (widget.selectedDate != null) {
        // 選択された日付の00:00から23:59までを設定
        final selectedDate = widget.selectedDate!;
        startDateTime =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDateTime = DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, 23, 59);
        // 新規作成時は終日で初期化
        isAllDay = true;

        // デバッグ用：選択された日付をログ出力
        print('DEBUG: Selected date for new schedule: $selectedDate');
        print('DEBUG: Start date set to: $startDateTime');
        print('DEBUG: End date set to: $endDateTime');
      } else {
        // 日付が選択されていない場合は今日の日付を設定
        final today = DateTime.now();
        startDateTime = DateTime(today.year, today.month, today.day);
        endDateTime = DateTime(today.year, today.month, today.day, 23, 59);
        isAllDay = true;

        // デバッグ用：今日の日付をログ出力
        print('DEBUG: No date selected, using today: $today');
      }
    }
  }

  void _showDateTimePicker() {
    schedule_util.showDateTimePicker(context, startDateTime, (date) {
      setState(() {
        startDateTime = date;
      });
    }, (date) {
      setState(() {
        startDateTime = date;
      });
    });
  }

  void _showDatePicker() {
    schedule_util.showDatePicker(context, startDateTime, (date) {
      setState(() {
        // 開始日時を選択した日付の00:00に設定
        startDateTime = DateTime(date.year, date.month, date.day);
        // 終了日時も同じ日付の23:59に設定
        endDateTime = DateTime(date.year, date.month, date.day, 23, 59);
      });
    }, (date) {
      setState(() {
        // 開始日時を選択した日付の00:00に設定
        startDateTime = DateTime(date.year, date.month, date.day);
        // 終了日時も同じ日付の23:59に設定
        endDateTime = DateTime(date.year, date.month, date.day, 23, 59);
      });
    });
  }

  // 色選択ダイアログを表示
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ラベルの色を選択'),
          content: Container(
            width: 300,
            height: 200,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: scheduleColors.length,
              itemBuilder: (context, index) {
                final color = scheduleColors[index];
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  // Colorを16進数文字列に変換
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  // 16進数文字列をColorに変換
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // アルファ値を追加
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(
                height: 46,
                child: Row(
                  children: [
                    sizedIconBox(Icons.title),
                    expandedTextField(
                        widget.initialSchedule != null ? 'タイトル（編集中）' : 'タイトル',
                        titleController)
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  sizedIconBox(Icons.access_time),
                  Switch(
                    value: isAllDay,
                    onChanged: (value) {
                      setState(() {
                        isAllDay = value;
                        if (value) {
                          // 終日がオンになった場合、選択された日付の00:00-23:59に設定
                          if (widget.selectedDate != null) {
                            final selectedDate = widget.selectedDate!;
                            startDateTime = DateTime(selectedDate.year,
                                selectedDate.month, selectedDate.day);
                            endDateTime = DateTime(selectedDate.year,
                                selectedDate.month, selectedDate.day, 23, 59);
                          }
                        } else {
                          // 終日がオフになった場合、現在の日付の現在時刻から1時間後に設定
                          final now = DateTime.now();
                          startDateTime = DateTime(now.year, now.month, now.day,
                              now.hour, now.minute);
                          endDateTime = startDateTime.add(Duration(hours: 1));
                        }
                      });
                    },
                  ),
                  Text('終日'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  sizedIconBox(Icons.calendar_month),
                  expandedOutlinedButton(
                      isAllDay
                          ? formatDate(startDateTime)
                          : formatDateTime(startDateTime),
                      4, () async {
                    isAllDay ? _showDatePicker() : _showDateTimePicker();
                  }),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("~")),
                  expandedOutlinedButton(
                      isAllDay
                          ? formatDate(endDateTime)
                          : formatDateTime(endDateTime),
                      4, () async {
                    isAllDay ? _showDatePicker() : _showDateTimePicker();
                  }),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  sizedIconBox(Icons.person),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: participationList.entries
                          .map((entry) => IconButton(
                              style: IconButton.styleFrom(
                                  backgroundColor:
                                      entry.value ? Colors.white : Colors.grey,
                                  shape: CircleBorder(),
                                  side: BorderSide(
                                      width: 4,
                                      color: entry.value
                                          ? themeColor
                                          : Colors.grey),
                                  padding: EdgeInsets.all(4)),
                              onPressed: () {
                                setState(() {
                                  participationList[entry.key] = !entry.value;
                                });
                              },
                              icon: Icon(Icons.person)))
                          .toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // 通知時刻
              Column(
                children: [
                  Row(
                    children: [
                      sizedIconBox(Icons.notifications),
                      SizedBox(height: 8),
                      Column(
                        children: [
                          Text('通知時刻'),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 2, left: 5),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: [
                        labelCheckbox('5分前', fiveMinutesBefore, (value) {
                          setState(() {
                            fiveMinutesBefore = value ?? false;
                          });
                        }),
                        labelCheckbox('10分前', tenMinutesBefore, (value) {
                          setState(() {
                            tenMinutesBefore = value ?? false;
                          });
                        }),
                        labelCheckbox('30分前', thirtyMinutesBefore, (value) {
                          setState(() {
                            thirtyMinutesBefore = value ?? false;
                          });
                        }),
                        labelCheckbox('1時間前', oneHourBefore, (value) {
                          setState(() {
                            oneHourBefore = value ?? false;
                          });
                        }),
                        labelCheckbox('3時間前', threeHoursBefore, (value) {
                          setState(() {
                            threeHoursBefore = value ?? false;
                          });
                        }),
                        labelCheckbox('1日', oneDayBefore, (value) {
                          setState(() {
                            oneDayBefore = value ?? false;
                          });
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // 色選択
              Row(
                children: [
                  sizedIconBox(Icons.palette),
                  SizedBox(width: 8),
                  Text('ラベルの色'),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: sizedIconBox(Icons.description),
                    ),
                    expandedTextField('メモ', memoController,
                        maxLines: 3, maxLength: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text('キャンセル'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('タイトルを入力してください'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final currentSpace =
                      ref.read(firestoreSpacesProvider)?.currentSpace;
                  if (currentSpace == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('スペースが選択されていません'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    bool success = false;

                    if (widget.initialSchedule != null) {
                      // 編集モード - 予定を更新
                      success = await ref
                          .read(scheduleFirestoreProvider.notifier)
                          .updateSchedule(
                            scheduleId: widget.initialSchedule!.id!,
                            title: titleController.text.trim(),
                            description: memoController.text.trim(),
                            startTime: startDateTime,
                            endTime: endDateTime,
                            color: _colorToHex(selectedColor),
                            isAllDay: isAllDay,
                          );
                    } else {
                      // 新規作成モード - 予定を追加
                      success = await ref
                          .read(scheduleFirestoreProvider.notifier)
                          .addSchedule(
                            title: titleController.text.trim(),
                            description: memoController.text.trim(),
                            startTime: startDateTime,
                            endTime: endDateTime,
                            color: _colorToHex(selectedColor),
                            isAllDay: isAllDay,
                          );
                    }

                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.initialSchedule != null
                              ? '予定を更新しました'
                              : '予定を追加しました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // カレンダー表示を強制更新
                      if (mounted) {
                        setState(() {});
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.initialSchedule != null
                              ? '予定の更新に失敗しました'
                              : '予定の追加に失敗しました'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print(
                        'DEBUG: Error ${widget.initialSchedule != null ? 'updating' : 'adding'} schedule: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラーが発生しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  // 従来のローカル保存も並行して実行（移行期間用）
                  SchedulerController(ScheduleInfrastructure())
                      .addSchedule(ScheduleModel(
                    title: titleController.text,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    memo: memoController.text,
                    isAllDay: isAllDay,
                    fiveMinutesBefore: fiveMinutesBefore,
                    tenMinutesBefore: tenMinutesBefore,
                    thirtyMinutesBefore: thirtyMinutesBefore,
                    oneHourBefore: oneHourBefore,
                    threeHoursBefore: threeHoursBefore,
                    sixHoursBefore: sixHoursBefore,
                    twelveHoursBefore: twelveHoursBefore,
                    oneDayBefore: oneDayBefore,
                    participationList: participationList,
                    color: _colorToHex(selectedColor),
                  ));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeColor,
                  side: const BorderSide(color: themeColor),
                ),
                child: Text(widget.initialSchedule != null ? '更新' : '追加'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
