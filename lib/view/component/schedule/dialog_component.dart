import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/controllers/scheduler_controller.dart';
import 'package:outi_log/infrastructure/schedule_infrastructure.dart';
import 'package:outi_log/models/schedule_model.dart';
import 'package:outi_log/utils/format.dart';
import 'package:outi_log/utils/schedule_util.dart' as schedule_util;
import 'package:outi_log/view/component/common.dart';
import 'package:outi_log/provider/event_provider.dart';

class DialogComponent extends StatefulWidget {
  final DateTime? selectedDate;

  const DialogComponent({super.key, this.selectedDate});

  @override
  State<DialogComponent> createState() => _DialogComponentState();
}

class _DialogComponentState extends State<DialogComponent> {
  String? title;
  bool isAllDay = true;
  DateTime startDateTime = DateTime.now();
  DateTime endDateTime = DateTime.now();
  String? memo;
  // Color? color;
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
    selectedDateTime = widget.selectedDate;
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
        startDateTime = date;
      });
    }, (date) {
      setState(() {
        startDateTime = date;
      });
    });
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
                    expandedTextField('タイトル', titleController)
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
                onPressed: () {
                  SchedulerController(ScheduleInfrastructure())
                      .addSchedule(ScheduleModel(
                    title: titleController.text,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    memo: memoController.text,
                    // color: color,
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
                  ));
                  if (titleController.text.isNotEmpty &&
                      selectedDateTime != null) {
                    Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeColor,
                  side: const BorderSide(color: themeColor),
                ),
                child: const Text('追加'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
