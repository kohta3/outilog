import 'package:flutter/material.dart';
import 'package:outi_log/constant/color.dart';
import 'package:outi_log/models/shopping_list_model.dart';
import 'package:outi_log/utils/format.dart';

class ShoppingListItemCard extends StatelessWidget {
  final ShoppingListItemModel item;
  final Function(bool) onTogglePurchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ShoppingListItemCard({
    super.key,
    required this.item,
    required this.onTogglePurchase,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // チェックボックス
            Checkbox(
              value: item.isPurchased,
              onChanged: (value) {
                onTogglePurchase(value ?? false);
              },
              activeColor: themeColor,
            ),
            const SizedBox(width: 12),

            // アイテム情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: item.isPurchased
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isPurchased
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  if (item.amount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(item.amount!),
                      style: TextStyle(
                        fontSize: 14,
                        color: item.isPurchased
                            ? Colors.grey.shade500
                            : themeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // アクションボタン
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
