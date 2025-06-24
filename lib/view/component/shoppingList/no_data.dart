import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';

class NoData extends StatelessWidget {
  const NoData({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            '買い物リストはまだありません',
            style: TextStyle(fontSize: 18, color: secondaryTextColor),
          ),
          const SizedBox(height: 8),
          const Text(
            '右下のボタンから新しいリストを追加しましょう',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
