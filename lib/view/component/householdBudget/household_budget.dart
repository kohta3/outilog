import 'package:flutter/material.dart';

Widget householdBudget(BuildContext context, Color color, String title,
    void Function()? onPressed) {
  return SizedBox(
    width: 100,
    child: Container(
      margin: const EdgeInsets.all(4),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(color: color)),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    ),
  );
}
