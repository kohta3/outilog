import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';

AppBar appBar(String title, bool isAddButton, Function()? onPressed) {
  return AppBar(
    centerTitle: true,
    title: Text(title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    backgroundColor: themeColor,
    actions: isAddButton
        ? [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: onPressed,
            ),
          ]
        : [],
  );
}

Widget expandedTextField(String label, TextEditingController controller,
    {String? errorText,
    bool isPassword = false,
    double? fontSize = 14,
    int? maxLines = 1,
    int? maxLength,
    Function(String)? onChanged}) {
  return Expanded(
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      obscureText: isPassword,
      onChanged: onChanged,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        errorText: errorText,
      ),
    ),
  );
}

Widget expandedOutlinedButton(
    String label, double borderRadius, Function()? onPressed) {
  return Expanded(
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(6),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

Widget labelCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
          width: 24,
          height: 24,
          child: Transform.scale(
              scale: 0.8, child: Checkbox(value: value, onChanged: onChanged))),
      SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 14)),
      SizedBox(width: 8),
    ],
  );
}

Widget sizedIconBox(IconData icon,
    {double? size = 24, Color? color = Colors.grey}) {
  return Padding(
    padding: EdgeInsets.only(right: 10),
    child: SizedBox(
      width: size,
      height: size,
      child: Icon(icon, color: color),
    ),
  );
}
