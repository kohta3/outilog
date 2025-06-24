import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';

class ShoppingListCard extends StatefulWidget {
  final Map<String, dynamic> listData;
  final VoidCallback onDelete;

  const ShoppingListCard(
      {super.key, required this.listData, required this.onDelete});

  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = (widget.listData['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  int _calculateTotalCost() {
    return items.fold<int>(0, (sum, item) {
      final cost = item['cost'] as int?;
      return sum + (cost ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.listData['name'],
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                  onPressed: widget.onDelete,
                  tooltip: '削除',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: dividerColor, thickness: 1),
            Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return CheckboxListTile(
                  title: Text(item['name'] as String,
                      style: const TextStyle(
                          fontSize: 16, color: primaryTextColor)),
                  value: item['checked'] as bool,
                  onChanged: (bool? value) {
                    setState(() {
                      items[index]['checked'] = value!;
                    });
                  },
                  activeColor: primaryColor,
                  secondary: SizedBox(
                    width: 70,
                    child: Text(
                      item['cost'] != null ? '¥${item['cost']}' : '-',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 16, color: secondaryTextColor),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
            const Divider(color: dividerColor, thickness: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('合計:',
                    style: TextStyle(fontSize: 16, color: secondaryTextColor)),
                const SizedBox(width: 8),
                Text(
                  '¥ ${_calculateTotalCost()}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
