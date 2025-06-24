import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

void showDateTimePicker(
    BuildContext context,
    DateTime? selectedDateTime,
    Function(DateTime) callbackOnChanged,
    Function(DateTime) callbackOnConfirm) {
  DatePicker.showDateTimePicker(
    context,
    showTitleActions: true,
    locale: LocaleType.jp,
    minTime: DateTime(2022, 1, 1),
    maxTime: DateTime(2023, 12, 31),
    onChanged: (date) {
      callbackOnChanged(date);
    },
    onConfirm: (date) {
      callbackOnConfirm(date);
    },
    currentTime: selectedDateTime ?? DateTime.now(),
  );
}

void showDatePicker(
    BuildContext context,
    DateTime? selectedDateTime,
    Function(DateTime) callbackOnChanged,
    Function(DateTime) callbackOnConfirm) {
  DatePicker.showDatePicker(
    context,
    showTitleActions: true,
    locale: LocaleType.jp,
    onChanged: (date) {
      callbackOnChanged(date);
    },
    onConfirm: (date) {
      callbackOnConfirm(date);
    },
    currentTime: selectedDateTime ?? DateTime.now(),
  );
}
