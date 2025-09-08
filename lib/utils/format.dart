import 'package:intl/intl.dart';

// 日時をyyyy/MM/dd HH:mmに変換する
String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}\n${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String formatDate(DateTime dateTime) {
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
}

String formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String formatMonth(DateTime dateTime) {
  return '${dateTime.year}/${dateTime.month}';
}

String formatMonthJp(DateTime dateTime) {
  return '${dateTime.year}年${dateTime.month}月';
}

String formatCurrency(double amount) {
  final formatter = NumberFormat('#,###');
  return formatter.format(amount);
}
